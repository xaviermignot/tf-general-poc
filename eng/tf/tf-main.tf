# module "cdn_profile" {
#   source = "./cdn_profile"

#   rg_name               = azurerm_resource_group.rg.name
#   location              = var.location
#   project               = var.project
#   cdn_location          = var.cdn_config.location
#   enable_static_website = contains(keys(local.endpoints), "web")
# }

# module "cdn_endpoint" {
#   for_each = local.endpoints
#   source   = "./cdn_endpoint"

#   rg_name              = azurerm_resource_group.rg.name
#   location             = var.location
#   project              = var.project
#   dns_zone_name        = var.dns_config.zone_name
#   dns_zone_rg_name     = var.dns_config.zone_rg_name
#   cdn_location         = var.cdn_config.location
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

module "acme" {
  source = "./acme"

  email            = var.certificate_config.email
  common_name      = "*.${var.dns_config.zone_name}"
  dns_zone_name    = var.dns_config.zone_name
  dns_zone_rg_name = var.dns_config.zone_rg_name
}

module "appgw-app-service-easy-auth" {
  source = "./appgw-app-service-easy-auth"

  rg_name  = azurerm_resource_group.rg.name
  location = var.location
  project  = var.project

  app_services        = local.app_services
  dns_zone_name       = var.dns_config.zone_name
  dns_zone_rg_name    = var.dns_config.zone_rg_name
  certificate_name    = var.certificate_config.name
  certificate_kv_name = var.certificate_config.kv_name
  certificate_rg_name = var.certificate_config.kv_rg_name
  organization_name   = var.certificate_config.organization_name
  certificate_email   = var.certificate_config.email

  wildcard_cert = {
    pfx_value    = module.acme.pfx_value
    pfx_password = module.acme.pfx_password
  }
}
