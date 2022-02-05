# module "cdn_profile" {
#   source = "./cdn_profile"

#   rg_name               = azurerm_resource_group.rg.name
#   location              = var.location
#   project               = var.project
#   cdn_location          = var.cdn_location
#   enable_static_website = contains(keys(local.endpoints), "web")
# }

# module "cdn_endpoint" {
#   for_each = local.endpoints
#   source   = "./cdn_endpoint"

#   rg_name              = azurerm_resource_group.rg.name
#   location             = var.location
#   project              = var.project
#   dns_zone_name        = var.dns_zone_name
#   dns_zone_rg_name     = var.dns_zone_rg_name
#   cdn_location         = var.cdn_location
#   endpoint_name        = each.key
#   storage_account_name = module.cdn_profile.storage_account_name
#   cdn_profile_name     = module.cdn_profile.cdn_profile_name
#   origin_type          = each.value

#   depends_on = [
#     module.cdn_profile
#   ]
# }

# module "servicebus" {
#   source = "./servicebus"

#   rg_name  = azurerm_resource_group.rg.name
#   location = var.location
#   project  = var.project
# }

module "appgw-app-service-easy-auth" {
  source = "./appgw-app-service-easy-auth"

  rg_name                   = azurerm_resource_group.rg.name
  location                  = var.location
  project                   = var.project
  app_service_custom_domain = var.app_service_custom_domain
  dns_zone_name             = var.dns_zone_name
  dns_zone_rg_name          = var.dns_zone_rg_name
  certificate_name          = var.certificate_name
  certificate_kv_name       = var.certificate_kv_name
  certificate_rg_name       = var.certificate_rg_name
  custom_domain_name        = var.custom_domain_name
  organization_name         = var.organization_name
}
