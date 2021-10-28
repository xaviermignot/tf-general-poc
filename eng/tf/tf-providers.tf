terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.82.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "2.7.0"
    }
  }
}

provider "azurerm" {
  features {}
}
