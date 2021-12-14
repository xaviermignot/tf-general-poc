resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.project}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location

  address_space = ["10.1.0.0/16"]
}

resource "azurerm_subnet" "appgw" {
  name                = "subnet-appgw"
  resource_group_name = azurerm_resource_group.rg.name

  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.1.1.0/24"]
  service_endpoints    = ["Microsoft.Storage"]
}

resource "azurerm_subnet" "app" {
  name                = "subnet-app"
  resource_group_name = azurerm_resource_group.rg.name

  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.1.2.0/24"]
}

resource "azurerm_subnet" "endpoints" {
  name                = "subnet-endpoints"
  resource_group_name = azurerm_resource_group.rg.name

  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.1.3.0/24"]
}

resource "azurerm_public_ip" "appgw" {
  name                = "pip-${var.project}-appgw"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location

  allocation_method = "Static"
  sku               = "Standard"
}
