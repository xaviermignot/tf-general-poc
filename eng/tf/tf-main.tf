module "cdn" {
  source = "./cdn"

  rg_name               = azurerm_resource_group.rg.name
  location              = var.location
  project               = var.project
  dns_zone_name         = var.dns_zone_name
  dns_zone_rg_name      = var.dns_zone_rg_name
  cdn_location          = var.cdn_location
  enable_static_website = false
}
