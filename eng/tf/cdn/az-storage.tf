resource "azurerm_storage_account" "account" {
  name                = "stor${replace(var.project, "-", "")}"
  resource_group_name = var.rg_name
  location            = var.location

  account_replication_type  = "LRS"
  account_tier              = "Standard"
  allow_blob_public_access  = true
  enable_https_traffic_only = true
  min_tls_version           = "TLS1_2"

  dynamic "static_website" {
    for_each = var.enable_static_website ? { foo = "bar" } : {}

    content {
      index_document = "index.html"
    }
  }
}

resource "azurerm_storage_container" "app" {
  count = local.number_of_apps

  name                  = "app-${count.index}"
  storage_account_name  = azurerm_storage_account.account.name
  container_access_type = "blob"
}

resource "azurerm_storage_blob" "index" {
  count = local.number_of_apps

  name                   = "index.html"
  storage_account_name   = azurerm_storage_account.account.name
  storage_container_name = azurerm_storage_container.app[count.index].name

  type           = "Block"
  content_type   = "text/html; charset=utf-8"
  source_content = "<html><body><h1>Hello from application n°${count.index} !!!</h1></body></html>"
}

resource "azurerm_storage_blob" "static_index" {
  count = var.enable_static_website ? 1 : 0

  name                   = "index.html"
  storage_account_name   = azurerm_storage_account.account.name
  storage_container_name = "$web"

  type           = "Block"
  content_type   = "text/html; charset=utf-8"
  source_content = "<html><body><h1>Hello from static web storage !!!</h1></body></html>"
}
