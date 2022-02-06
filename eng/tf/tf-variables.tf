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

variable "certificate_config" {
  type = object({
    name              = string
    kv_name           = string
    kv_rg_name        = string
    organization_name = string
  })
}
