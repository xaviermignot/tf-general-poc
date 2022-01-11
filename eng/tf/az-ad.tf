resource "azuread_group" "app" {
  count = local.number_of_apps

  display_name     = "Grp-CDN-Contributors-App${count.index}"
  security_enabled = true
}

resource "azurerm_role_assignment" "container" {
  count = local.number_of_apps

  scope                = azurerm_storage_container.app[count.index].resource_manager_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azuread_group.app[count.index].id
}

resource "azurerm_role_assignment" "account" {
  count = local.number_of_apps

  scope                = azurerm_storage_account.account.id
  role_definition_name = "Reader"
  principal_id         = azuread_group.app[count.index].id
}
