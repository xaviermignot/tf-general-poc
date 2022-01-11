data "azurerm_storage_account" "account" {
  name                = var.storage_account_name
  resource_group_name = var.rg_name
}

resource "azurerm_storage_container" "app" {
  name                  = var.app_name
  storage_account_name  = data.azurerm_storage_account.account.name
  container_access_type = "blob"
}

resource "azurerm_storage_blob" "index" {
  name                   = "index.html"
  storage_account_name   = data.azurerm_storage_account.account.name
  storage_container_name = azurerm_storage_container.app.name

  type           = "Block"
  content_type   = "text/html; charset=utf-8"
  source_content = "<html><body><h1>Hello from ${var.app_name} !!!</h1></body></html>"
}
