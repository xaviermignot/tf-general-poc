resource "azurerm_dns_cname_record" "app" {
  name                = "cdn-${var.endpoint_name}"
  zone_name           = var.dns_zone_name
  resource_group_name = var.dns_zone_rg_name
  ttl                 = 3600
  record              = azurerm_cdn_endpoint.app.host_name
}

resource "azurerm_cdn_endpoint_custom_domain" "app" {
  name            = "cdn-dns-app"
  cdn_endpoint_id = azurerm_cdn_endpoint.app.id
  host_name       = "${azurerm_dns_cname_record.app.name}.${var.dns_zone_name}"

  # Provisioner as Terraform does not provide a way to enable the TLS feature of CDN custom domains
  provisioner "local-exec" {
    command = <<EOT
      az login --service-principal -u $ARM_CLIENT_ID -p $ARM_CLIENT_SECRET -t $ARM_TENANT_ID
      az cdn custom-domain enable-https -g ${var.rg_name} --profile-name ${var.cdn_profile_name} --endpoint-name ${azurerm_cdn_endpoint.app.name} -n ${self.name}
    EOT
  }
}
