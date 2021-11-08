resource "azurerm_container_registry" "acr" {
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  name                = "acr${replace(var.project, "-", "")}"

  sku = "Basic"
}
