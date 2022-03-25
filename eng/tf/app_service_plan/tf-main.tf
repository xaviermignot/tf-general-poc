resource "azurerm_app_service_plan" "plan" {
  name                = "plan-${var.project}"
  location            = var.location
  resource_group_name = var.rg_name

  sku {
    tier     = "Standard"
    size     = "S1"
    capacity = 1
  }

  kind     = "Linux"
  reserved = true
}

