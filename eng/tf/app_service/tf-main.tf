locals {
  platforms = {
    "docker" = {
      linux_fx_version         = "DOCKER|${var.platform_app.version}",
      dotnet_framework_version = null
    },
    "dotnet" = {
      linux_fx_version         = "DOTNETCORE|${var.platform_app.version}",
      dotnet_framework_version = "v${var.platform_app.version}"
    }
  }
  platform_prefixes = {
    "docker" = {
      linux_fx_version         = "DOCKER",
      dotnet_framework_version = null
    },
    "dotnet" = {
      linux_fx_version         = "DOTNETCORE",
      dotnet_framework_version = "v"
    }
  }
}

resource "azurerm_app_service" "app" {
  name                = "web-${var.project}-${var.name}"
  location            = var.location
  resource_group_name = var.rg_name
  app_service_plan_id = var.app_service_plan_id

  site_config {
    linux_fx_version         = "${local.platform_prefixes[var.platform_app.type].linux_fx_version}|${var.platform_app.version}"
    dotnet_framework_version = local.platform_prefixes[var.platform_app.type].dotnet_framework_version != null ? "${local.platform_prefixes[var.platform_app.type].dotnet_framework_version}${var.platform_app.version}" : null

    always_on = true

    health_check_path = "/healthcheck"
  }

  app_settings = {
    "DOCKER_REGISTRY_SERVER_URL" = var.platform_app.type == "docker" ? "https://index.docker.io/v1" : null
  }
}

resource "azurerm_app_service_slot" "staging" {
  name                = "staging"
  location            = var.location
  resource_group_name = var.rg_name
  app_service_plan_id = var.app_service_plan_id
  app_service_name    = azurerm_app_service.app.name

  site_config {
    linux_fx_version         = "${local.platform_prefixes[var.platform_slot.type].linux_fx_version}|${var.platform_slot.version}"
    dotnet_framework_version = local.platform_prefixes[var.platform_slot.type].dotnet_framework_version != null ? "${local.platform_prefixes[var.platform_slot.type].dotnet_framework_version}${var.platform_slot.version}" : null

    always_on = true

    health_check_path = "/healthcheck"
  }

  app_settings = {
    "DOCKER_REGISTRY_SERVER_URL" = var.platform_slot.type == "docker" ? "https://index.docker.io/v1" : null
  }
}

# resource "azurerm_app_service_active_slot" "active_slot" {
#   resource_group_name   = var.rg_name
#   app_service_name      = azurerm_app_service.app.name
#   app_service_slot_name = var.active_slot_name
# }

# TXT record for verifying domain ownership
resource "azurerm_dns_txt_record" "app" {
  name                = "asuid.${azurerm_app_service.app.name}"
  zone_name           = var.dns_zone_name
  resource_group_name = var.dns_zone_rg_name
  ttl                 = 300

  record {
    value = azurerm_app_service.app.custom_domain_verification_id
  }
}

# CNAME record
resource "azurerm_dns_cname_record" "app" {
  name                = azurerm_app_service.app.name
  zone_name           = var.dns_zone_name
  resource_group_name = var.dns_zone_rg_name
  ttl                 = 300

  record = azurerm_app_service.app.default_site_hostname
}

# Bind app services to custom domains
resource "azurerm_app_service_custom_hostname_binding" "app" {
  hostname            = "${azurerm_app_service.app.name}.${var.dns_zone_name}"
  app_service_name    = azurerm_app_service.app.name
  resource_group_name = var.rg_name

  depends_on = [azurerm_dns_txt_record.app]
}

# Binding between the custom domains and the wildcard certificate
resource "azurerm_app_service_certificate_binding" "acme" {
  hostname_binding_id = azurerm_app_service_custom_hostname_binding.app.id
  certificate_id      = var.app_service_certificate_id
  ssl_state           = "SniEnabled"
}
