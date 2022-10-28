variable "location" {
  type        = string
  description = "the location to use for all resources"
}

variable "project" {
  type        = string
  description = "the project name to use in all resource names"
}

# variable "cdn_config" {
#   type = object({
#     location              = string
#     enable_static_website = bool
#   })
# }

variable "dns_config" {
  type = object({
    zone_name    = string
    zone_rg_name = string
  })
}

variable "certificate_config" {
  type = object({
    name              = string
    kv_name           = string
    kv_rg_name        = string
    organization_name = string
    email             = string
  })
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
  }
}
