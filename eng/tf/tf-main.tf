module "cdn_profile" {
  source = "./cdn_profile"

  rg_name               = azurerm_resource_group.rg.name
  location              = var.location
  project               = var.project
  cdn_location          = var.cdn_location
  enable_static_website = false
}

module "cdn_endpoint" {
  count = local.number_of_apps
  source = "./cdn_endpoint"

  rg_name               = azurerm_resource_group.rg.name
  location              = var.location
  project               = var.project
  dns_zone_name         = var.dns_zone_name
  dns_zone_rg_name      = var.dns_zone_rg_name
  cdn_location          = var.cdn_location
  app_name              = "app-${count.index}"
  storage_account_name  = module.cdn_profile.storage_account_name
  cdn_profile_name      = module.cdn_profile.cdn_profile_name

  depends_on = [
    module.cdn_profile
  ]
}
