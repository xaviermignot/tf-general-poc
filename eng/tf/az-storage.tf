resource "azurerm_storage_account" "account" {
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  name                = "stor${replace(var.project, "-", "")}"

  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_share" "share" {
  storage_account_name = azurerm_storage_account.account.name
  name                 = "app-share"
}
