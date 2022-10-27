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

# module "app_service_cert" {
#   source = "./app_service_cert"

#   rg_name  = azurerm_resource_group.rg.name
#   location = var.location
#   project  = var.project

#   wildcard_cert = {
#     pfx_value    = module.acme.pfx_value
#     pfx_password = module.acme.pfx_password
#   }
# }

# module "app_service_plan" {
#   source = "./app_service_plan"

#   rg_name  = azurerm_resource_group.plan.name
#   location = var.location
#   project  = var.project
# }

# module "app_service_docker" {
#   source = "./app_service"

#   rg_name  = azurerm_resource_group.rg.name
#   location = var.location
#   project  = var.project

#   name = "docker"

#   platform_app = {
#     type    = "docker"
#     version = "xaviermignot/tfgeneralpoc:host"
#   }

#   platform_slot = {
#     type    = "docker"
#     version = "xaviermignot/tfgeneralpoc:hello"
#   }

#   active_slot_name = "staging"

#   dns_zone_name              = var.dns_config.zone_name
#   dns_zone_rg_name           = var.dns_config.zone_rg_name
#   app_service_plan_id        = module.app_service_plan.app_service_plan_id
#   app_service_certificate_id = module.app_service_cert.app_service_certificate_id
# }

# module "app_service_package" {
#   source = "./app_service"

#   rg_name  = azurerm_resource_group.rg.name
#   location = var.location
#   project  = var.project

#   name = "package"

#   platform_app = {
#     type    = "dotnet"
#     version = "5.0"
#   }

#   platform_slot = {
#     type    = "dotnet"
#     version = "6.0"
#   }

#   active_slot_name = "staging"

#   dns_zone_name              = var.dns_config.zone_name
#   dns_zone_rg_name           = var.dns_config.zone_rg_name
#   app_service_plan_id        = module.app_service_plan.app_service_plan_id
#   app_service_certificate_id = module.app_service_cert.app_service_certificate_id
# }
