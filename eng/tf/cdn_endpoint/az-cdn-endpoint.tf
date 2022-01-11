resource "azurerm_cdn_endpoint" "app" {
  name                = "cdn-${var.project}-${var.app_name}"
  profile_name        = var.cdn_profile_name
  location            = var.cdn_location
  resource_group_name = var.rg_name

  is_http_allowed    = false
  optimization_type  = "GeneralWebDelivery"
  origin_host_header = data.azurerm_storage_account.account.primary_blob_host
  origin_path        = "/${azurerm_storage_container.app.name}"

  origin {
    name      = "blob"
    host_name = data.azurerm_storage_account.account.primary_blob_host
  }
}
