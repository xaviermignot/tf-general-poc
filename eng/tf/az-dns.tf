data "azurerm_dns_zone" "dns" {
  name                = var.dns_zone_name
  resource_group_name = var.dns_zone_rg_name
}

locals {
  app_service_subdomain = "appgw-app"
}

# DNS records for app service
# A record to link subdomain to app gateway
# resource "azurerm_dns_a_record" "app_gw_app" {
#   name                = local.app_service_subdomain
#   zone_name           = data.azurerm_dns_zone.dns.name
#   resource_group_name = data.azurerm_dns_zone.dns.resource_group_name
#   ttl                 = 300
#   target_resource_id  = azurerm_public_ip.appgw.id
# }

# CNAME record to link subdomain to app service
resource "azurerm_dns_cname_record" "app_gw_app" {
  name                = local.app_service_subdomain
  zone_name           = data.azurerm_dns_zone.dns.name
  resource_group_name = data.azurerm_dns_zone.dns.resource_group_name
  ttl                 = 300
  record              = azurerm_app_service.app["auth"].default_site_hostname
}

# TXT record for verifying domain ownership
resource "azurerm_dns_txt_record" "app" {
  name                = "asuid.${local.app_service_subdomain}"
  zone_name           = data.azurerm_dns_zone.dns.name
  resource_group_name = data.azurerm_dns_zone.dns.resource_group_name
  ttl                 = 300

  record {
    value = azurerm_app_service.app["auth"].custom_domain_verification_id
  }
}

# DNS records for static storage
resource "azurerm_dns_a_record" "app_gw_static" {
  name                = "appgw-static"
  zone_name           = data.azurerm_dns_zone.dns.name
  resource_group_name = data.azurerm_dns_zone.dns.resource_group_name
  ttl                 = 300
  target_resource_id  = azurerm_public_ip.appgw.id
}
