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
  for_each = var.app_services

  name                = each.value.name
  location            = var.location
  resource_group_name = var.rg_name
  app_service_plan_id = azurerm_app_service_plan.plan.id

  site_config {
    linux_fx_version = "DOCKER|xaviermignot/tfgeneralpoc:host"
  }

  app_settings = {
    "DOCKER_REGISTRY_SERVER_URL"                      = "https://index.docker.io/v1"
    "APPINSIGHTS_INSTRUMENTATIONKEY"                  = azurerm_application_insights.ai.instrumentation_key
    "APPINSIGHTS_PROFILERFEATURE_VERSION"             = "1.0.0"
    "APPINSIGHTS_SNAPSHOTFEATURE_VERSION"             = "1.0.0"
    "APPLICATIONINSIGHTS_CONFIGURATION_CONTENT"       = ""
    "APPLICATIONINSIGHTS_CONNECTION_STRING"           = azurerm_application_insights.ai.connection_string
    "ApplicationInsightsAgent_EXTENSION_VERSION"      = "~3"
    "DiagnosticServices_EXTENSION_VERSION"            = "~3"
    "InstrumentationEngine_EXTENSION_VERSION"         = "disabled"
    "SnapshotDebugger_EXTENSION_VERSION"              = "disabled"
    "XDT_MicrosoftApplicationInsights_BaseExtensions" = "disabled"
    "XDT_MicrosoftApplicationInsights_Mode"           = "recommended"
    "XDT_MicrosoftApplicationInsights_PreemptSdk"     = "disabled"
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE"             = false
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

# Single wildcard App Service for all App Services
resource "azurerm_app_service_certificate" "wildcard" {
  name                = "cert-wildcard"
  resource_group_name = var.rg_name
  location            = var.location
  pfx_blob            = var.wildcard_cert.pfx_value
  password            = var.wildcard_cert.pfx_password
}

# Bind app services to custom domains
resource "azurerm_app_service_custom_hostname_binding" "app" {
  for_each = { for k, v in var.app_services : k => v if v.use_custom_domain }

  hostname            = "${each.value.custom_subdomain}.${var.dns_zone_name}"
  app_service_name    = each.value.name
  resource_group_name = var.rg_name

  depends_on = [azurerm_dns_txt_record.app]
}

# Binding between the custom domains and the wildcard certificate
resource "azurerm_app_service_certificate_binding" "acme" {
  for_each = azurerm_app_service_custom_hostname_binding.app

  hostname_binding_id = each.value.id
  certificate_id      = azurerm_app_service_certificate.wildcard.id
  ssl_state           = "SniEnabled"
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
  for_each = var.app_services

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
