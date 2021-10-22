resource "azurerm_servicebus_namespace" "namespace" {
  name                = "sb-${var.project}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  sku                 = "Standard"
}

resource "azurerm_servicebus_topic" "topic" {
  name                = "testTopic"
  namespace_name      = azurerm_servicebus_namespace.namespace.name
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_servicebus_subscription" "subscription" {
  name                = "testSubscription"
  resource_group_name = azurerm_resource_group.rg.name
  namespace_name      = azurerm_servicebus_namespace.namespace.name
  topic_name          = azurerm_servicebus_topic.topic.name
  max_delivery_count  = 2
}

resource "azurerm_servicebus_subscription_rule" "correlationRule" {
  name                = "correlationFilter"
  subscription_name   = azurerm_servicebus_subscription.subscription.name
  namespace_name      = azurerm_servicebus_namespace.namespace.name
  topic_name          = azurerm_servicebus_topic.topic.name
  resource_group_name = azurerm_resource_group.rg.name

  filter_type = "CorrelationFilter"

  correlation_filter {
    properties = {
      messageType = "AddGatewayToInstallation"
    }
  }
}

resource "azurerm_servicebus_subscription_rule" "sqlRule" {
  name                = "sqlFilter"
  subscription_name   = azurerm_servicebus_subscription.subscription.name
  namespace_name      = azurerm_servicebus_namespace.namespace.name
  topic_name          = azurerm_servicebus_topic.topic.name
  resource_group_name = azurerm_resource_group.rg.name

  filter_type = "SqlFilter"

  sql_filter = "deviceId LIKE 'XEVFR-%' AND messageType = 'AddGatewayToInstallation'"
}
