locals {
  ssl_certificate_name           = "appgw-ssl-certificate"
  frontend_ip_configuration_name = "appgw-frontend-ip-configuration"
  http_port_name                 = "appgw-frontend-port-http"
  http_settings_name             = "appgw-http-settings"
  http_probe_name                = "appgw-http-probe"
  https_port_name                = "appgw-frontend-port-https"
  aps_http_settings_name         = "appgw-aps-http-settings"
  aps_probe_name                 = "appgw-aps-probe"
}

data "azurerm_key_vault" "cert" {
  name                = var.certificate_kv_name
  resource_group_name = var.certificate_rg_name
}

data "azurerm_key_vault_certificate" "cert" {
  name         = var.certificate_name
  key_vault_id = data.azurerm_key_vault.cert.id
}

resource "azurerm_user_assigned_identity" "app_gw" {
  name                = "msi-appgw-${var.project}"
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_role_assignment" "app_gw_kv" {
  scope                = data.azurerm_key_vault.cert.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.app_gw.principal_id
}

resource "azurerm_application_gateway" "app_gw" {
  name                = "appgw-${var.project}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location

  sku {
    tier     = "Standard_v2"
    name     = "Standard_v2"
    capacity = 1
  }

  identity {
    identity_ids = [azurerm_user_assigned_identity.app_gw.id]
  }

  # Common blocks: certificates, ip configuration, ...
  ssl_certificate {
    name                = local.ssl_certificate_name
    key_vault_secret_id = data.azurerm_key_vault_certificate.cert.secret_id
  }

  gateway_ip_configuration {
    name      = "appgw-ip-configuration"
    subnet_id = azurerm_subnet.appgw.id
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_configuration_name
    public_ip_address_id = azurerm_public_ip.appgw.id
  }

  # Common blocks for http: port, http settings and probe
  frontend_port {
    name = local.http_port_name
    port = 80
  }

  backend_http_settings {
    name                                = local.http_settings_name
    cookie_based_affinity               = "Disabled"
    protocol                            = "Http"
    port                                = 80
    probe_name                          = local.http_probe_name
    request_timeout                     = 30
    pick_host_name_from_backend_address = true
  }

  probe {
    name                                      = local.http_probe_name
    protocol                                  = "Http"
    path                                      = "/"
    pick_host_name_from_backend_http_settings = true
    interval                                  = 10
    timeout                                   = 30
    unhealthy_threshold                       = 3
  }

  # Common blocks for https: port, http settings and probe
  frontend_port {
    name = local.https_port_name
    port = 443
  }

  # Blocks for Azure storage: listeners, rules, backend pool, ...
  http_listener {
    name                           = "appgw-https-storage-listener"
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.https_port_name
    host_name                      = var.storage_custom_domain
    ssl_certificate_name           = local.ssl_certificate_name
    protocol                       = "Https"
  }

  http_listener {
    name                           = "appgw-http-storage-listener"
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.http_port_name
    host_name                      = var.storage_custom_domain
    protocol                       = "Http"
  }

  backend_address_pool {
    name  = "appgw-backend-address-pool-storage"
    fqdns = [azurerm_storage_account.account.primary_web_host]
  }

  redirect_configuration {
    name                 = "appgw-http-storage-redirect"
    redirect_type        = "Permanent"
    target_listener_name = "appgw-https-storage-listener"
  }

  request_routing_rule {
    name                       = "appgw-routing-rule-https-storage"
    rule_type                  = "Basic"
    http_listener_name         = "appgw-https-storage-listener"
    backend_address_pool_name  = "appgw-backend-address-pool-storage"
    backend_http_settings_name = local.http_settings_name
  }

  request_routing_rule {
    name                        = "appgw-routing-rule-http-storage"
    rule_type                   = "Basic"
    http_listener_name          = "appgw-http-storage-listener"
    redirect_configuration_name = "appgw-http-storage-redirect"
  }

  # Blocks for App Service: probe, http settins, listeners, rules, backend pool, ...
  # Probe & http settings are specific to app service as it depends on the custom domain
  probe {
    name                = local.aps_probe_name
    protocol            = "Https"
    host                = var.app_service_custom_domain
    path                = "/"
    interval            = 10
    timeout             = 30
    unhealthy_threshold = 3

    match {
      status_code = ["200-399", "401"]
    }
  }

  backend_http_settings {
    name                  = local.aps_http_settings_name
    cookie_based_affinity = "Disabled"
    path                  = "/"
    protocol              = "Https"
    port                  = 443
    probe_name            = local.aps_probe_name
    request_timeout       = 30
  }

  http_listener {
    name                           = "appgw-https-app-service-listener"
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.https_port_name
    host_name                      = var.app_service_custom_domain
    ssl_certificate_name           = local.ssl_certificate_name
    protocol                       = "Https"
  }

  http_listener {
    name                           = "appgw-http-app-service-listener"
    frontend_ip_configuration_name = local.frontend_ip_configuration_name
    frontend_port_name             = local.http_port_name
    host_name                      = var.app_service_custom_domain
    protocol                       = "Http"
  }

  redirect_configuration {
    name                 = "appgw-http-app-service-redirect"
    redirect_type        = "Permanent"
    target_listener_name = "appgw-https-app-service-listener"
  }

  backend_address_pool {
    name  = "appgw-backend-address-pool-app-service"
    fqdns = [azurerm_app_service.app["auth"].default_site_hostname]
  }

  request_routing_rule {
    name                       = "appgw-routing-rule-https-app-service"
    rule_type                  = "Basic"
    http_listener_name         = "appgw-https-app-service-listener"
    backend_address_pool_name  = "appgw-backend-address-pool-app-service"
    backend_http_settings_name = local.aps_http_settings_name
  }

  request_routing_rule {
    name                        = "appgw-routing-rule-http-app-service"
    rule_type                   = "Basic"
    http_listener_name          = "appgw-http-app-service-listener"
    redirect_configuration_name = "appgw-http-app-service-redirect"
  }
}
