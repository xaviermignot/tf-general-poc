variable "location" {
  type        = string
  description = "the location to use for all resources"
}

variable "project" {
  type        = string
  description = "the project name to use in all resource names"
}

variable "custom_domain_name" {
  type        = string
  description = "the custom domain name for app gateway"
}

variable "organization_name" {
  type        = string
  description = "the name of the organization for the ssl cert"
}

variable "whitelisted_ips" {
  type        = set(string)
  description = "list of IPs to whitelist on various resources"
}
