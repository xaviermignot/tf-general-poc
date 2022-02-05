resource "azurerm_application_insights" "ai" {
  name                = "ai-${var.project}"
  location            = var.location
  resource_group_name = var.rg_name
  application_type    = "web"
}
