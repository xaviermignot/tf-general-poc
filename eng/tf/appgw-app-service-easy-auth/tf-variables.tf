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

variable "dns_zone_name" {
  type        = string
  description = "the name of the DNS zone already created in Azure"
}

variable "dns_zone_rg_name" {
  type        = string
  description = "the name of the resource group containing the DNS zone"
}

variable "app_services" {
  type = map(object({
    name              = string
    easy_auth         = bool
    custom_subdomain  = string
    use_custom_domain = bool
    use_package       = optional(bool, false)
  }))
}

variable "wildcard_cert" {
  type = object({
    pfx_value    = string
    pfx_password = string
  })
}
