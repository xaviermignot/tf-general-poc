resource "azurerm_cdn_profile" "profile" {
  name                = "cdn-${var.project}-profile"
  location            = var.cdn_location
  resource_group_name = var.rg_name
  sku                 = "Standard_Microsoft"
}

resource "azurerm_cdn_endpoint" "app" {
  count = local.number_of_apps

  name                = "cdn-${var.project}-app${count.index}"
  profile_name        = azurerm_cdn_profile.profile.name
  location            = var.cdn_location
  resource_group_name = var.rg_name

  is_http_allowed    = false
  optimization_type  = "GeneralWebDelivery"
  origin_host_header = azurerm_storage_account.account.primary_blob_host
  origin_path        = "/${azurerm_storage_container.app[count.index].name}"

  origin {
    name      = "blob"
    host_name = azurerm_storage_account.account.primary_blob_host
  }
}

resource "azurerm_cdn_endpoint" "static_website" {
  count = var.enable_static_website ? 1 : 0

  name                = "cdn-${var.project}-web"
  profile_name        = azurerm_cdn_profile.profile.name
  location            = var.cdn_location
  resource_group_name = var.rg_name

  is_http_allowed    = false
  optimization_type  = "GeneralWebDelivery"
  origin_host_header = azurerm_storage_account.account.primary_web_host

  origin {
    name      = "static-http"
    host_name = azurerm_storage_account.account.primary_web_host
  }
}
