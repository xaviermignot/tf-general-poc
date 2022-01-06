resource "azurerm_application_insights" "ai" {
  name                = "ai-${var.project}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"
}
