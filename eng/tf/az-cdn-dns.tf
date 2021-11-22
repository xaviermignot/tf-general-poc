data "azurerm_dns_zone" "zone" {
  name                = var.dns_zone_name
  resource_group_name = var.dns_zone_rg_name
}

resource "azurerm_dns_cname_record" "app" {
  count = local.number_of_apps

  name                = "cdn-app${count.index}"
  zone_name           = data.azurerm_dns_zone.zone.name
  resource_group_name = data.azurerm_dns_zone.zone.resource_group_name
  ttl                 = 3600
  target_resource_id  = azurerm_cdn_endpoint.app[count.index].id
}

resource "azurerm_cdn_endpoint_custom_domain" "app" {
  count = local.number_of_apps

  name            = "cdn-dns-app"
  cdn_endpoint_id = azurerm_cdn_endpoint.app[count.index].id
  host_name       = "${azurerm_dns_cname_record.app[count.index].name}.${data.azurerm_dns_zone.zone.name}"
}
