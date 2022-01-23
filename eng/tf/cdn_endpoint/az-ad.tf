locals {
  container_rm_id = var.origin_type == "blob" ? azurerm_storage_container.app[0].resource_manager_id : data.azurerm_storage_container.static_website[0].resource_manager_id
}

resource "azuread_group" "app" {
  display_name     = "Grp-CDN-Contributors-${var.endpoint_name}"
  security_enabled = true
}

resource "azurerm_role_assignment" "container" {
  scope                = local.container_rm_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_group.app.id
}

resource "azurerm_role_assignment" "account" {
  scope                = data.azurerm_storage_account.account.id
  role_definition_name = "Reader"
  principal_id         = azuread_group.app.id
}
