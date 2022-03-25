resource "azurerm_resource_group" "rg" {
  name     = "rg-${var.project}"
  location = var.location
}

resource "azurerm_resource_group" "plan" {
  name     = "rg-${var.project}-plan"
  location = var.location
}
