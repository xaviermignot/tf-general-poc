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

resource "azurerm_user_assigned_identity" "app_gw" {
  name                = "msi-appgw-${var.project}"
  location            = var.location
  resource_group_name = var.rg_name
}

resource "azurerm_application_gateway" "app_gw" {
  name                = "appgw-${var.project}"
  resource_group_name = var.rg_name
  location            = var.location

  sku {
    tier     = "WAF_v2"
    name     = "WAF_v2"
    capacity = 1
  }

  firewall_policy_id = azurerm_web_application_firewall_policy.waf.id

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.app_gw.id]
  }

  # Common blocks: certificates, ip configuration, ...
  ssl_certificate {
    name     = local.ssl_certificate_name
    data     = var.wildcard_cert.pfx_value
    password = var.wildcard_cert.pfx_password
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

  # Common blocks for https: port, http settings and probe
  frontend_port {
    name = local.https_port_name
    port = 443
  }

  # Probes for app services
  dynamic "probe" {
    for_each = var.app_services
    iterator = app

    content {
      name                = "${local.aps_probe_name}-${app.key}"
      protocol            = "Https"
      host                = "${app.value["custom_subdomain"]}.${var.dns_zone_name}"
      path                = "/"
      interval            = 10
      timeout             = 30
      unhealthy_threshold = 3

      match {
        status_code = ["200-399", "401"]
      }
    }
  }

  # HTTP settings for app services
  dynamic "backend_http_settings" {
    for_each = var.app_services

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
    for_each = var.app_services
    iterator = app

    content {
      name                           = "appgw-https-aps-listener-${app.key}"
      frontend_ip_configuration_name = local.frontend_ip_configuration_name
      frontend_port_name             = local.https_port_name
      host_name                      = "${app.value["custom_subdomain"]}.${var.dns_zone_name}"
      ssl_certificate_name           = local.ssl_certificate_name
      protocol                       = "Https"
    }
  }

  # HTTP listeners for app services (redirections to HTTPS)
  dynamic "http_listener" {
    for_each = var.app_services

    content {
      name                           = "appgw-http-aps-listener-${http_listener.key}"
      frontend_ip_configuration_name = local.frontend_ip_configuration_name
      frontend_port_name             = local.http_port_name
      host_name                      = "${http_listener.value["custom_subdomain"]}.${var.dns_zone_name}"
      protocol                       = "Http"
    }
  }

  dynamic "redirect_configuration" {
    for_each = var.app_services

    content {
      name                 = "appgw-http-aps-redirect-${redirect_configuration.key}"
      redirect_type        = "Permanent"
      target_listener_name = "appgw-https-aps-listener-${redirect_configuration.key}"
    }
  }

  # HTTPS listeners for scm
  dynamic "http_listener" {
    for_each = var.app_services

    content {
      name                           = "appgw-https-aps-scm-listener-${http_listener.key}"
      frontend_ip_configuration_name = local.frontend_ip_configuration_name
      frontend_port_name             = local.https_port_name
      host_name                      = "${http_listener.value["custom_subdomain"]}.scm.${var.dns_zone_name}"
      ssl_certificate_name           = local.ssl_certificate_name
      protocol                       = "Https"
    }
  }

  # Backend pools for app services
  dynamic "backend_address_pool" {
    for_each = var.app_services

    content {
      name  = "appgw-backend-address-pool-aps-${backend_address_pool.key}"
      fqdns = [azurerm_linux_web_app.app[backend_address_pool.key].default_hostname]
    }
  }

  # Routing rules for HTTPS
  dynamic "request_routing_rule" {
    for_each = var.app_services

    content {
      name                       = "appgw-routing-rule-https-aps-${request_routing_rule.key}"
      rule_type                  = "Basic"
      http_listener_name         = "appgw-https-aps-listener-${request_routing_rule.key}"
      backend_address_pool_name  = "appgw-backend-address-pool-aps-${request_routing_rule.key}"
      backend_http_settings_name = "${local.aps_http_settings_name}-${request_routing_rule.key}"
      priority                   = (index(keys(var.app_services), request_routing_rule.key) + 1) * 10 + 100
    }
  }

  # Routing rules for HTTP (redirections to HTTPS)
  dynamic "request_routing_rule" {
    for_each = var.app_services

    content {
      name                        = "appgw-routing-rule-http-aps-${request_routing_rule.key}"
      rule_type                   = "Basic"
      http_listener_name          = "appgw-http-aps-listener-${request_routing_rule.key}"
      redirect_configuration_name = "appgw-http-aps-redirect-${request_routing_rule.key}"
      priority                    = (index(keys(var.app_services), request_routing_rule.key) + 1) * 10 + 200
    }
  }

  # Blocks for SCM: probe accepting 401 and http settings using this probe
  probe {
    name                                      = "${local.aps_probe_name}-scm"
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
    name                                = "${local.aps_http_settings_name}-scm"
    cookie_based_affinity               = "Disabled"
    path                                = "/"
    protocol                            = "Https"
    port                                = 443
    probe_name                          = "${local.aps_probe_name}-scm"
    request_timeout                     = 30
    pick_host_name_from_backend_address = true
  }

  # Backend pools for scm
  dynamic "backend_address_pool" {
    for_each = var.app_services

    content {
      name  = "appgw-backend-address-pool-aps-scm-${backend_address_pool.key}"
      fqdns = ["${azurerm_linux_web_app.app[backend_address_pool.key].name}.scm.azurewebsites.net"]
    }
  }

  # Routing rules for scm
  dynamic "request_routing_rule" {
    for_each = var.app_services

    content {
      name                       = "appgw-routing-rule-https-aps-scm-${request_routing_rule.key}"
      rule_type                  = "Basic"
      http_listener_name         = "appgw-https-aps-scm-listener-${request_routing_rule.key}"
      backend_address_pool_name  = "appgw-backend-address-pool-aps-scm-${request_routing_rule.key}"
      backend_http_settings_name = "${local.aps_http_settings_name}-scm"
      priority                   = (index(keys(var.app_services), request_routing_rule.key) + 1) * 10 + 300
    }
  }

  # This depends_on forces the creation of backend pools AFTER private endpoints, eliminating
  # 403 errors between the gateway and the backends
  depends_on = [azurerm_private_endpoint.app]
}
