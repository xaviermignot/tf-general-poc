# module "cdn_profile" {
#   source = "./cdn_profile"

#   rg_name               = azurerm_resource_group.rg.name
#   location              = var.location
#   project               = var.project
#   cdn_location          = var.cdn_config.location
#   enable_static_website = contains(keys(local.endpoints), "web")
# }

# locals {
#   endpoints = merge({ for i in range(1, 6) : "app-${i}" => "blob" }, { web = "static_website" })
# }

# module "cdn_endpoint" {
#   for_each = local.endpoints
#   source   = "./cdn_endpoint"

#   rg_name              = azurerm_resource_group.rg.name
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

locals {
  app_services = {
    "auth" = {
      name              = "web-${var.project}-auth"
      easy_auth         = true
      custom_subdomain  = "appgw-app-auth"
      use_custom_domain = true
    }
    "no-auth" = {
      name              = "web-${var.project}-no-auth"
      easy_auth         = false
      custom_subdomain  = "appgw-app-no-auth"
      use_custom_domain = true
    }
    "new" = {
      name              = "web-${var.project}-new"
      easy_auth         = false
      custom_subdomain  = "appgw-app-new"
      use_custom_domain = true
    }
    "auth-custom" = {
      name              = "web-${var.project}-auth-custom"
      easy_auth         = true
      custom_subdomain  = "appgw-app-auth-custom"
      use_custom_domain = true
    }
    "package" = {
      name              = "web-${var.project}-package"
      easy_auth         = false
      custom_subdomain  = "appgw-app-package"
      use_custom_domain = true
      use_package       = true
    }
  }
}

module "appgw-app-service-easy-auth" {
  source = "./appgw-app-service-easy-auth"

  rg_name  = azurerm_resource_group.rg.name
  location = var.location
  project  = var.project

  app_services        = local.app_services
  dns_zone_name       = var.dns_config.zone_name
  dns_zone_rg_name    = var.dns_config.zone_rg_name

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

#   blue_app = {
#     type    = "docker"
#     version = "xaviermignot/tfgeneralpoc"
#     tag     = "host"
#   }

#   green_app = {
#     type    = "docker"
#     version = "xaviermignot/tfgeneralpoc"
#     tag     = "hello"
#   }

#   active_app = "blue"

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

#   blue_app = {
#     type    = "dotnet"
#     version = "5.0"
#   }

#   green_app = {
#     type    = "dotnet"
#     version = "6.0"
#   }

#   active_app = "blue"

#   dns_zone_name              = var.dns_config.zone_name
#   dns_zone_rg_name           = var.dns_config.zone_rg_name
#   app_service_plan_id        = module.app_service_plan.app_service_plan_id
#   app_service_certificate_id = module.app_service_cert.app_service_certificate_id
# }
