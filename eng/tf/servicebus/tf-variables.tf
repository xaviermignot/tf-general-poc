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
