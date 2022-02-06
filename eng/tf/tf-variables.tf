variable "location" {
  type        = string
  description = "the location to use for all resources"
}

variable "project" {
  type        = string
  description = "the project name to use in all resource names"
}

variable "cdn_config" {
  type = object({
    location              = string
    enable_static_website = bool
  })
}

variable "dns_config" {
  type = object({
    zone_name    = string
    zone_rg_name = string
  })
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

variable "app_service_custom_domain" {
  type        = string
  description = "the custom domain for app service"
}

variable "custom_domain_name" {
  type        = string
  description = "the custom domain name for app gateway"
}

variable "organization_name" {
  type        = string
  description = "the name of the organization for the ssl cert"
}
