resource "azurerm_application_gateway" "app_gw" {
  name                = "appgw-${var.project}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location

  sku {
    tier     = "Standard"
    name     = "Standard_Small"
    capacity = 1
  }

  ssl_certificate {
    name     = "appgw-ssl-certificate"
    data     = pkcs12_from_pem.self_signed_cert.result
    password = random_password.self_signed_cert.result
  }

  gateway_ip_configuration {
    name      = "appgw-ip-configuration"
    subnet_id = azurerm_subnet.appgw.id
  }

  frontend_port {
    name = "appgw-frontend-port-https"
    port = 443
  }

  frontend_ip_configuration {
    name                 = "appgw-frontend-ip-configuration"
    public_ip_address_id = azurerm_public_ip.appgw.id
  }

  http_listener {
    name                           = "appgw-https-storage-listener"
    frontend_ip_configuration_name = "appgw-frontend-ip-configuration"
    frontend_port_name             = "appgw-frontend-port-https"
    host_name                      = var.storage_custom_domain
    ssl_certificate_name           = "appgw-ssl-certificate"
    protocol                       = "Https"
  }

  backend_address_pool {
    name  = "appgw-backend-address-pool-storage"
    fqdns = [azurerm_storage_account.account.primary_web_host]
  }

  backend_http_settings {
    name                  = "appgw-backend-http-settings-storage"
    cookie_based_affinity = "Disabled"
    protocol              = "Http"
    port                  = 80
    probe_name            = "appgw-probe-storage"
    request_timeout       = 30
    host_name             = azurerm_storage_account.account.primary_web_host
  }

  probe {
    name                = "appgw-probe-storage"
    protocol            = "Http"
    path                = "/"
    host                = azurerm_storage_account.account.primary_web_host
    interval            = 10
    timeout             = 30
    unhealthy_threshold = 3
  }

  request_routing_rule {
    name                       = "appgw-routing-rule-https"
    rule_type                  = "Basic"
    http_listener_name         = "appgw-https-storage-listener"
    backend_address_pool_name  = "appgw-backend-address-pool-storage"
    backend_http_settings_name = "appgw-backend-http-settings-storage"
  }

  http_listener {
    name                           = "appgw-https-app-service-listener"
    frontend_ip_configuration_name = "appgw-frontend-ip-configuration"
    frontend_port_name             = "appgw-frontend-port-https"
    host_name                      = var.app_service_custom_domain
    ssl_certificate_name           = "appgw-ssl-certificate"
    protocol                       = "Https"
  }

  backend_address_pool {
    name  = "appgw-backend-address-pool-app-service"
    fqdns = [azurerm_app_service.app.default_site_hostname]
  }

  probe {
    name                = "appgw-probe-app-service"
    protocol            = "Https"
    path                = "/"
    host                = azurerm_app_service.app.default_site_hostname
    interval            = 10
    timeout             = 30
    unhealthy_threshold = 3
  }

  backend_http_settings {
    name                  = "appgw-backend-http-settings-app-service"
    cookie_based_affinity = "Disabled"
    path                  = "/"
    protocol              = "Https"
    port                  = 443
    probe_name            = "appgw-probe-app-service"
    request_timeout       = 30
    host_name             = azurerm_app_service.app.default_site_hostname
  }

  request_routing_rule {
    name                       = "appgw-routing-rule-https-app-service"
    rule_type                  = "Basic"
    http_listener_name         = "appgw-https-app-service-listener"
    backend_address_pool_name  = "appgw-backend-address-pool-app-service"
    backend_http_settings_name = "appgw-backend-http-settings-app-service"
  }
}
