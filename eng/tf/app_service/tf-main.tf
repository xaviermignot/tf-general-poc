resource "azurerm_linux_web_app" "app" {
  name                = "web-${var.project}-${var.name}"
  location            = var.location
  resource_group_name = var.rg_name
  service_plan_id     = var.app_service_plan_id

  site_config {
    application_stack {
      docker_image     = var.blue_app.type == "docker" ? var.blue_app.version : null
      docker_image_tag = var.blue_app.type == "docker" ? var.blue_app.tag : null

      dotnet_version = var.blue_app.type == "dotnet" ? var.blue_app.version : null
    }

    always_on = true

    health_check_path = "/healthcheck"
  }

  app_settings = {
    "DOCKER_REGISTRY_SERVER_URL" = var.blue_app.type == "docker" ? "https://index.docker.io/v1" : null
  }
}

resource "azurerm_linux_web_app_slot" "staging" {
  name           = "staging"
  app_service_id = azurerm_linux_web_app.app.id

  site_config {
    application_stack {
      docker_image     = var.green_app.type == "docker" ? var.green_app.version : null
      docker_image_tag = var.green_app.type == "docker" ? var.green_app.tag : null

      dotnet_version = var.green_app.type == "dotnet" ? var.green_app.version : null
    }

    always_on = true

    health_check_path = "/healthcheck"
  }

  app_settings = {
    "DOCKER_REGISTRY_SERVER_URL" = var.green_app.type == "docker" ? "https://index.docker.io/v1" : null
  }
}

resource "azurerm_web_app_active_slot" "active_slot" {
  count = var.active_app == "green" ? 1 : 0

  slot_id = azurerm_linux_web_app_slot.staging.id
}

# TXT record for verifying domain ownership
resource "azurerm_dns_txt_record" "app" {
  name                = "asuid.${azurerm_linux_web_app.app.name}"
  zone_name           = var.dns_zone_name
  resource_group_name = var.dns_zone_rg_name
  ttl                 = 300

  record {
    value = azurerm_linux_web_app.app.custom_domain_verification_id
  }
}

# CNAME record
resource "azurerm_dns_cname_record" "app" {
  name                = azurerm_linux_web_app.app.name
  zone_name           = var.dns_zone_name
  resource_group_name = var.dns_zone_rg_name
  ttl                 = 300

  record = azurerm_linux_web_app.app.default_hostname
}

# Bind app services to custom domains
resource "azurerm_app_service_custom_hostname_binding" "app" {
  hostname            = "${azurerm_linux_web_app.app.name}.${var.dns_zone_name}"
  app_service_name    = azurerm_linux_web_app.app.name
  resource_group_name = var.rg_name

  depends_on = [azurerm_dns_txt_record.app]
}

# Binding between the custom domains and the wildcard certificate
resource "azurerm_app_service_certificate_binding" "acme" {
  hostname_binding_id = azurerm_app_service_custom_hostname_binding.app.id
  certificate_id      = var.app_service_certificate_id
  ssl_state           = "SniEnabled"
}
