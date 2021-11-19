resource "azurerm_cdn_profile" "profile" {
  name                = "cdn-${var.project}-profile"
  location            = var.cdn_location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard_Microsoft"
}

resource "azurerm_cdn_endpoint" "app" {
  name                = "cdn-${var.project}-app"
  profile_name        = azurerm_cdn_profile.profile.name
  location            = var.cdn_location
  resource_group_name = azurerm_resource_group.rg.name

  is_http_allowed = false

  origin {
    name      = "blob"
    host_name = azurerm_storage_account.account.primary_blob_host
  }
}

resource "azurerm_cdn_endpoint" "static_website" {
  name                = "cdn-${var.project}-web"
  profile_name        = azurerm_cdn_profile.profile.name
  location            = var.cdn_location
  resource_group_name = azurerm_resource_group.rg.name

  is_http_allowed = false

  origin {
    name      = "static-http"
    host_name = azurerm_storage_account.account.primary_web_host
  }
}
