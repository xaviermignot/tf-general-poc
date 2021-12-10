data "azurerm_dns_zone" "dns" {
  name                = var.dns_zone_name
  resource_group_name = var.dns_zone_rg_name
}

resource "azurerm_dns_cname_record" "app" {
  name                = "appgw-app"
  zone_name           = data.azurerm_dns_zone.dns.name
  resource_group_name = data.azurerm_dns_zone.dns.resource_group_name
  ttl                 = 300
  record              = azurerm_app_service.app["auth"].default_site_hostname
}

resource "azurerm_dns_txt_record" "app" {
  name                = "asuid.${azurerm_dns_cname_record.app.name}"
  zone_name           = data.azurerm_dns_zone.dns.name
  resource_group_name = data.azurerm_dns_zone.dns.resource_group_name
  ttl                 = 300

  record {
    value = azurerm_app_service.app["auth"].custom_domain_verification_id
  }
}
