resource "azuread_group" "app" {
  display_name     = "Grp-CDN-Contributors-${var.app_name}"
  security_enabled = true
}

resource "azurerm_role_assignment" "container" {
  scope                = azurerm_storage_container.app.resource_manager_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_group.app.id
}

resource "azurerm_role_assignment" "account" {
  scope                = data.azurerm_storage_account.account.id
  role_definition_name = "Reader"
  principal_id         = azuread_group.app.id
}
