variable "cdn_location" {
  type        = string
  description = "the location to use for the CDN resources"
}

variable "dns_zone_name" {
  type        = string
  description = "the name of the dns zone in Azure"
}

variable "dns_zone_rg_name" {
  type        = string
  description = "the name of the dns zone resource group"
}
