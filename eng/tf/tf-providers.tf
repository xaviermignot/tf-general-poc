terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "2.89.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "2.12.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.1.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "3.1.0"
    }
    pkcs12 = {
      source  = "chilicat/pkcs12"
      version = "0.0.7"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.1.0"
    }
    tfe = {
      source  = "hashicorp/tfe"
      version = "0.26.1"
    }
    time = {
      source  = "hashicorp/time"
      version = "0.7.2"
    }
  }
}

provider "azurerm" {
  features {}
}
