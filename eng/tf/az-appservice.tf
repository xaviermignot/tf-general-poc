resource "azurerm_app_service_plan" "plan" {
  name                = "plan-${var.project}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

  kind     = "Linux"
  reserved = true

  sku {
    tier = "Basic"
    size = "B1"
  }
}

resource "azurerm_app_service" "app" {
  for_each = {
    "auth"    = true
    "no-auth" = false
  }

  name                = "web-${var.project}-${each.key}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  app_service_plan_id = azurerm_app_service_plan.plan.id

  site_config {
    linux_fx_version = "DOCKER|xaviermignot/tfgeneralpoc:latest"
  }

  app_settings = {
    "DOCKER_REGISTRY_SERVER_URL"          = "https://index.docker.io/v1"
    "APPINSIGHTS_INSTRUMENTATIONKEY"      = azurerm_application_insights.ai.instrumentation_key
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = false
  }

  auth_settings {
    enabled = each.value

    default_provider              = "AzureActiveDirectory"
    unauthenticated_client_action = "RedirectToLoginPage"
    issuer                        = "https://sts.windows.net/${data.azuread_client_config.current.tenant_id}"
    runtime_version               = "v2"

    active_directory {
      client_id     = each.value ? azuread_application.easy_auth.application_id : "00000000-0000-0000-0000-000000000000"
      client_secret = each.value ? azuread_application_password.easy_auth.value : null
    }
  }
}

resource "azurerm_app_service_custom_hostname_binding" "app" {
  hostname            = trim(azurerm_dns_cname_record.app.fqdn, ".")
  app_service_name    = azurerm_app_service.app["auth"].name
  resource_group_name = azurerm_app_service.app["auth"].resource_group_name

  depends_on = [azurerm_dns_txt_record.app]

  lifecycle {
    ignore_changes = [ssl_state, thumbprint]
  }
}

resource "azurerm_app_service_managed_certificate" "app" {
  custom_hostname_binding_id = azurerm_app_service_custom_hostname_binding.app.id
}

resource "azurerm_app_service_certificate_binding" "app" {
  hostname_binding_id = azurerm_app_service_custom_hostname_binding.app.id
  certificate_id      = azurerm_app_service_managed_certificate.app.id
  ssl_state           = "SniEnabled"
}
