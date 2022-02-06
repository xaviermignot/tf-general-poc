variable "rg_name" {
  type        = string
  description = "the name of the main resource group"
}

variable "location" {
  type        = string
  description = "the location to use for all resources"
}

variable "project" {
  type        = string
  description = "the project name to use in all resource names"
}

variable "organization_name" {
  type        = string
  description = "the name of the organization for the ssl cert"
}

variable "dns_zone_name" {
  type        = string
  description = "the name of the DNS zone already created in Azure"
}

variable "dns_zone_rg_name" {
  type        = string
  description = "the name of the resource group containing the DNS zone"
}

variable "certificate_name" {
  type = string
}

variable "certificate_kv_name" {
  type = string
}

variable "certificate_rg_name" {
  type = string
}

locals {
  app_services = {
    "auth" = {
      name             = "web-${var.project}-auth"
      easy_auth        = true
      custom_subdomain = "appgw-app-auth"
    }
    "no-auth" = {
      name             = "web-${var.project}-no-auth"
      easy_auth        = false
      custom_subdomain = "appgw-app-no-auth"
    }
    "new" = {
      name             = "web-${var.project}-new"
      easy_auth        = false
      custom_subdomain = "appgw-app-new"
    }
  }
}
