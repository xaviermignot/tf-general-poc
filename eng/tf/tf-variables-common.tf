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
