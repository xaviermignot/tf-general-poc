resource "tls_private_key" "private_key" {
  algorithm = "RSA"
}

resource "acme_registration" "reg" {
  account_key_pem = tls_private_key.private_key.private_key_pem
  email_address   = var.email
}

resource "random_password" "cert" {
  length  = 24
  special = true
}

resource "acme_certificate" "cert" {
  account_key_pem          = acme_registration.reg.account_key_pem
  common_name              = var.common_name
  certificate_p12_password = random_password.cert.result

  dns_challenge {
    provider = "azuredns"

    config = {
      AZURE_RESOURCE_GROUP = var.dns_zone_rg_name
      AZURE_ZONE_NAME      = var.dns_zone_name
      AZURE_TTL            = 300
    }
  }
}
