resource "azurerm_linux_web_app_plan" "plan" {
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

resource "azurerm_linux_web_app" "app" {
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  name                = "web-${var.project}"
  app_service_plan_id = azurerm_linux_web_app_plan.plan.id

  site_config {
    linux_fx_version = "DOCKER|appsvc/dotnetcore:latest"
  }

  app_settings = {
    "DOCKER_REGISTRY_SERVER_URL" = "https://index.docker.io/v1"
  }
}
