resource "azurerm_app_service_plan" "plan" {
  name                = "plan-${var.project}"
  location            = var.location
  resource_group_name = var.rg_name

  sku {
    tier     = "Basic"
    size     = "B1"
    capacity = 2
  }

  kind     = "Linux"
  reserved = true
}

