data "azurerm_storage_account" "account" {
  name                = var.storage_account_name
  resource_group_name = var.rg_name
}

data "azurerm_storage_container" "static_website" {
  count = var.origin_type == "web" ? 1 : 0

  name                 = "$web"
  storage_account_name = data.azurerm_storage_account.account.name
}

resource "azurerm_storage_container" "app" {
  count = var.origin_type == "blob" ? 1 : 0

  name                  = var.endpoint_name
  storage_account_name  = data.azurerm_storage_account.account.name
  container_access_type = "blob"
}

resource "azurerm_storage_blob" "index" {
  name                   = "index.html"
  storage_account_name   = data.azurerm_storage_account.account.name
  storage_container_name = var.origin_type == "blob" ? azurerm_storage_container.app[0].name : "$web"

  type           = "Block"
  content_type   = "text/html; charset=utf-8"
  source_content = "<html><body><h1>Hello from ${var.endpoint_name} !!!</h1></body></html>"
}
