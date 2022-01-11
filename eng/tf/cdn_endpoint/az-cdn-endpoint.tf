locals {
  origin_host = var.origin_type == "blob" ? data.azurerm_storage_account.account.primary_blob_host : data.azurerm_storage_account.account.primary_web_host
}

resource "azurerm_cdn_endpoint" "app" {
  name                = "cdn-${var.project}-${var.endpoint_name}"
  profile_name        = var.cdn_profile_name
  location            = var.cdn_location
  resource_group_name = var.rg_name

  is_http_allowed    = false
  optimization_type  = "GeneralWebDelivery"
  origin_host_header = local.origin_host
  origin_path        = "/${var.origin_type == "blob" ? azurerm_storage_container.app[0].name : "$web"}"

  origin {
    name      = var.origin_type
    host_name = local.origin_host
  }
}
