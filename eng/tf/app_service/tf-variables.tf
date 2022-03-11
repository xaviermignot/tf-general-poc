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

variable "name" {
  type        = string
  description = "The name of the Web App (that will be prefixed by the project)"
}

variable "platform_type" {
  type        = string
  description = "The platform to use for deployment. Can be either docker or dotnet for now"
}

variable "platform_version" {
  type        = string
  description = "The version of the platform to use. Can be a version number like 6.0 for dotnet or an image for docker."
  default     = null
}

variable "dns_zone_name" {
  type        = string
  description = "the name of the DNS zone already created in Azure"
}

variable "dns_zone_rg_name" {
  type        = string
  description = "the name of the resource group containing the DNS zone"
}

variable "app_service_plan_id" {
  type        = string
  description = "The identifier of the app service plan"
}

variable "app_service_certificate_id" {
  type        = string
  description = "The identifier of the app service certificate"
}
