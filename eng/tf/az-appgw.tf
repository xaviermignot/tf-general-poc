locals {
  ssl_certificate_name           = "appgw-ssl-certificate"
  ssl_scm_certificate_name       = "appg-ssl-scm-certificate"
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

  ssl_certificate {
    name     = local.ssl_scm_certificate_name
    data     = pkcs12_from_pem.self_signed_cert.result
    password = random_password.self_signed_cert.result
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

  probe {
    name                                      = "${local.aps_probe_name}-default"
    protocol                                  = "Https"
    pick_host_name_from_backend_http_settings = true
    path                                      = "/"
    interval                                  = 10
    timeout                                   = 30
    unhealthy_threshold                       = 3

    match {
      status_code = ["200-399", "401"]
    }
  }

  backend_http_settings {
    name                                = "${local.aps_http_settings_name}-default"
    cookie_based_affinity               = "Disabled"
    path                                = "/"
    protocol                            = "Https"
    port                                = 443
    probe_name                          = "${local.aps_probe_name}-default"
    request_timeout                     = 30
    pick_host_name_from_backend_address = true
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
  dynamic "probe" {
    for_each = local.app_services

    content {
      name                = "${local.aps_probe_name}-${probe.key}"
      protocol            = "Https"
      host                = "${probe.value["custom_subdomain"]}.${var.dns_zone_name}"
      path                = "/"
      interval            = 10
      timeout             = 30
      unhealthy_threshold = 3

      match {
        status_code = ["200-399", "401"]
      }
    }
  }

  # Backend pools for app services
  dynamic "backend_http_settings" {
    for_each = local.app_services

    content {
      name                  = "${local.aps_http_settings_name}-${backend_http_settings.key}"
      cookie_based_affinity = "Disabled"
      path                  = "/"
      protocol              = "Https"
      port                  = 443
      probe_name            = "${local.aps_probe_name}-${backend_http_settings.key}"
      request_timeout       = 30
    }
  }

  # HTTPS listeners for app services
  dynamic "http_listener" {
    for_each = local.app_services

    content {
      name                           = "appgw-https-aps-listener-${http_listener.key}"
      frontend_ip_configuration_name = local.frontend_ip_configuration_name
      frontend_port_name             = local.https_port_name
      host_name                      = "${http_listener.value["custom_subdomain"]}.${var.dns_zone_name}"
      ssl_certificate_name           = local.ssl_certificate_name
      protocol                       = "Https"
    }
  }

  # HTTP listeners for app services (redirections to HTTPS)
  dynamic "http_listener" {
    for_each = local.app_services

    content {
      name                           = "appgw-http-aps-listener-${http_listener.key}"
      frontend_ip_configuration_name = local.frontend_ip_configuration_name
      frontend_port_name             = local.http_port_name
      host_name                      = "${http_listener.value["custom_subdomain"]}.${var.dns_zone_name}"
      protocol                       = "Http"
    }
  }

  dynamic "redirect_configuration" {
    for_each = local.app_services

    content {
      name                 = "appgw-http-aps-redirect-${redirect_configuration.key}"
      redirect_type        = "Permanent"
      target_listener_name = "appgw-https-aps-listener-${redirect_configuration.key}"
    }
  }

  # HTTPS listeners for scm
  dynamic "http_listener" {
    for_each = local.app_services

    content {
      name                           = "appgw-https-aps-scm-listener-${http_listener.key}"
      frontend_ip_configuration_name = local.frontend_ip_configuration_name
      frontend_port_name             = local.https_port_name
      host_name                      = "${http_listener.value["custom_subdomain"]}.scm.${var.dns_zone_name}"
      ssl_certificate_name           = local.ssl_scm_certificate_name
      protocol                       = "Https"
    }
  }

  # Backend pools for app services
  dynamic "backend_address_pool" {
    for_each = local.app_services

    content {
      name  = "appgw-backend-address-pool-aps-${backend_address_pool.key}"
      fqdns = [azurerm_app_service.app[backend_address_pool.key].default_site_hostname]
    }
  }

  # Backend pools for scm
  dynamic "backend_address_pool" {
    for_each = local.app_services

    content {
      name  = "appgw-backend-address-pool-aps-scm-${backend_address_pool.key}"
      fqdns = ["${azurerm_app_service.app[backend_address_pool.key].name}.scm.azurewebsites.net"]
    }
  }

  # Routing rules for HTTPS
  dynamic "request_routing_rule" {
    for_each = local.app_services

    content {
      name                       = "appgw-routing-rule-https-aps-${request_routing_rule.key}"
      rule_type                  = "Basic"
      http_listener_name         = "appgw-https-aps-listener-${request_routing_rule.key}"
      backend_address_pool_name  = "appgw-backend-address-pool-aps-${request_routing_rule.key}"
      backend_http_settings_name = "${local.aps_http_settings_name}-${request_routing_rule.key}"
    }
  }

  # Routing rules for HTTP (redirections to HTTPS)
  dynamic "request_routing_rule" {
    for_each = local.app_services

    content {
      name                        = "appgw-routing-rule-http-aps-${request_routing_rule.key}"
      rule_type                   = "Basic"
      http_listener_name          = "appgw-http-aps-listener-${request_routing_rule.key}"
      redirect_configuration_name = "appgw-http-aps-redirect-${request_routing_rule.key}"
    }
  }

  # Routing rules for scm
  dynamic "request_routing_rule" {
    for_each = local.app_services

    content {
      name                       = "appgw-routing-rule-https-aps-scm-${request_routing_rule.key}"
      rule_type                  = "Basic"
      http_listener_name         = "appgw-https-aps-scm-listener-${request_routing_rule.key}"
      backend_address_pool_name  = "appgw-backend-address-pool-aps-scm-${request_routing_rule.key}"
      backend_http_settings_name = "${local.aps_http_settings_name}-default"
    }
  }
}
