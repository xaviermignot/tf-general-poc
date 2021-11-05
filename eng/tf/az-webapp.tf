resource "azurerm_app_service_plan" "plan" {
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  name                = "plan-${var.project}"

  kind     = "Linux"
  reserved = true

  sku {
    tier = "Basic"
    size = "B1"
  }
}

resource "azurerm_app_service" "app" {
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  name                = "web-${var.project}"
  app_service_plan_id = azurerm_app_service_plan.plan.id

  site_config {
    linux_fx_version = "DOCKER|xaviermignot/tfgeneralpoc:aspnet-app"
  }

  app_settings = {
    "DOCKER_REGISTRY_SERVER_URL" = "https://index.docker.io/v1"
  }

  storage_account {
    name         = "app-files"
    type         = "AzureFiles"
    account_name = azurerm_storage_account.account.name
    share_name   = azurerm_storage_share.share.name
    access_key   = azurerm_storage_account.account.primary_access_key
    mount_path   = "/home/site/wwwroot/assets"
  }

  storage_account {
    name         = "default-files"
    type         = "AzureFiles"
    account_name = azurerm_storage_account.account.name
    share_name   = azurerm_storage_share.share.name
    access_key   = azurerm_storage_account.account.primary_access_key
    mount_path   = "/defaulthome/hostingstart/wwwroot/assets"
  }
}
