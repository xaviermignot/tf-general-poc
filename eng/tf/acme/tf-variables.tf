variable "email" {
  type = string
}

variable "common_name" {
  type = string
}

variable "dns_zone_name" {
  type        = string
  description = "the name of the DNS zone already created in Azure"
}

variable "dns_zone_rg_name" {
  type        = string
  description = "the name of the resource group containing the DNS zone"
}
