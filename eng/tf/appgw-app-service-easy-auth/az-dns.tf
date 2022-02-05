data "azurerm_dns_zone" "dns" {
  name                = var.dns_zone_name
  resource_group_name = var.dns_zone_rg_name
}

locals {
  app_service_subdomain = "appgw-app"
}

# DNS records for app service
# A records to link subdomain to app gateway
resource "azurerm_dns_a_record" "app_gw_app" {
  for_each = local.app_services

  name                = each.value.custom_subdomain
  zone_name           = data.azurerm_dns_zone.dns.name
  resource_group_name = data.azurerm_dns_zone.dns.resource_group_name
  ttl                 = 300
  target_resource_id  = azurerm_public_ip.appgw.id

  # Create the A records once the short-lived CNAME records have been removed
  depends_on = [
    null_resource.cname_remove
  ]
}

# A records for scm
resource "azurerm_dns_a_record" "app_gw_scm" {
  for_each = local.app_services

  name                = "${each.value.custom_subdomain}.scm"
  zone_name           = data.azurerm_dns_zone.dns.name
  resource_group_name = data.azurerm_dns_zone.dns.resource_group_name
  ttl                 = 300
  target_resource_id  = azurerm_public_ip.appgw.id
}

# TXT records for verifying domain ownership
resource "azurerm_dns_txt_record" "app" {
  for_each = local.app_services

  name                = "asuid.${each.value.custom_subdomain}"
  zone_name           = data.azurerm_dns_zone.dns.name
  resource_group_name = data.azurerm_dns_zone.dns.resource_group_name
  ttl                 = 300

  record {
    value = azurerm_app_service.app[each.key].custom_domain_verification_id
  }
}

# Wait for DNS propagation
resource "time_sleep" "dns_app" {
  for_each = local.app_services

  create_duration = "10s"

  depends_on = [
    azurerm_dns_txt_record.app,
    azurerm_dns_a_record.app_gw_app,
    azurerm_dns_a_record.app_gw_scm
  ]
}