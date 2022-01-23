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
