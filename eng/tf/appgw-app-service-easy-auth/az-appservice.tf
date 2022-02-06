resource "azurerm_app_service_plan" "plan" {
  name                = "plan-${var.project}"
  location            = var.location
  resource_group_name = var.rg_name

  kind     = "Linux"
  reserved = true

  sku {
    tier = "PremiumV2"
    size = "P1v2"
  }
}

resource "azurerm_app_service" "app" {
  for_each = local.app_services

  name                = each.value.name
  location            = var.location
  resource_group_name = var.rg_name
  app_service_plan_id = azurerm_app_service_plan.plan.id

  site_config {
    linux_fx_version = "DOCKER|xaviermignot/tfgeneralpoc.slim:latest"
  }

  app_settings = {
    "DOCKER_REGISTRY_SERVER_URL"          = "https://index.docker.io/v1"
    "APPINSIGHTS_INSTRUMENTATIONKEY"      = azurerm_application_insights.ai.instrumentation_key
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = false
  }

  auth_settings {
    enabled = each.value.easy_auth

    default_provider              = "AzureActiveDirectory"
    unauthenticated_client_action = "RedirectToLoginPage"
    issuer                        = "https://sts.windows.net/${data.azuread_client_config.current.tenant_id}"
    runtime_version               = "v2"

    active_directory {
      client_id     = each.value.easy_auth ? azuread_application.easy_auth[each.key].application_id : "00000000-0000-0000-0000-000000000000"
      client_secret = each.value.easy_auth ? azuread_application_password.easy_auth[each.key].value : null
    }
  }
}

# Bind app services to custom domains
resource "azurerm_app_service_custom_hostname_binding" "app" {
  for_each = local.app_services

  hostname            = "${each.value.custom_subdomain}.${var.dns_zone_name}"
  app_service_name    = each.value.name
  resource_group_name = var.rg_name

  depends_on = [azurerm_dns_txt_record.app]

  lifecycle {
    ignore_changes = [ssl_state, thumbprint]
  }

  # Short-lived CNAME record required for managed certificate binding
  provisioner "local-exec" {
    command = <<EOT
      az login --service-principal -u $ARM_CLIENT_ID -p $ARM_CLIENT_SECRET -t $ARM_TENANT_ID
      az network dns record-set cname set-record -g ${var.dns_zone_rg_name} -z ${var.dns_zone_name} -n ${each.value.custom_subdomain} -c ${each.value.name}.azurewebsites.net
    EOT
  }
}

# Managed certificates & bindings
resource "azurerm_app_service_managed_certificate" "app" {
  for_each = local.app_services

  custom_hostname_binding_id = azurerm_app_service_custom_hostname_binding.app[each.key].id
}

resource "azurerm_app_service_certificate_binding" "app" {
  for_each = azurerm_app_service_custom_hostname_binding.app

  hostname_binding_id = each.value.id
  certificate_id      = azurerm_app_service_managed_certificate.app[each.key].id
  ssl_state           = "SniEnabled"
}

# Deletion of CNAME record to avoid conflicts with upcoming A record pointing to gateway public IP
resource "null_resource" "cname_remove" {
  for_each = local.app_services

  provisioner "local-exec" {
    command = <<EOT
      az login --service-principal -u $ARM_CLIENT_ID -p $ARM_CLIENT_SECRET -t $ARM_TENANT_ID
      az network dns record-set cname remove-record -g ${var.dns_zone_rg_name} -z ${var.dns_zone_name} -n ${each.value.custom_subdomain} -c ${each.value.name}.azurewebsites.net
    EOT
  }

  depends_on = [azurerm_app_service_certificate_binding.app]
}

# Tempo after CNAME record deletion
resource "time_sleep" "cname_create" {
  create_duration = "10s"

  depends_on = [null_resource.cname_remove]
}

# VNet integration
resource "azurerm_app_service_virtual_network_swift_connection" "app" {
  for_each = azurerm_app_service.app

  app_service_id = each.value.id
  subnet_id      = azurerm_subnet.app.id
}

# Private DNS zone for private endpoint
resource "azurerm_private_dns_zone" "app" {
  name                = "privatelink.azurewebsites.net"
  resource_group_name = var.rg_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "app" {
  name                = azurerm_virtual_network.vnet.name
  resource_group_name = var.rg_name

  virtual_network_id    = azurerm_virtual_network.vnet.id
  private_dns_zone_name = azurerm_private_dns_zone.app.name
}

# Private endpoints
resource "azurerm_private_endpoint" "app" {
  for_each = local.app_services

  name                = each.value.name
  resource_group_name = var.rg_name
  location            = var.location
  subnet_id           = azurerm_subnet.endpoints.id

  private_service_connection {
    name                           = each.value.name
    private_connection_resource_id = azurerm_app_service.app[each.key].id
    is_manual_connection           = false

    subresource_names = ["sites"]
  }

  private_dns_zone_group {
    name                 = azurerm_private_dns_zone.app.name
    private_dns_zone_ids = [azurerm_private_dns_zone.app.id]
  }
}
