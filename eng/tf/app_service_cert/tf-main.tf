data "azurerm_client_config" "current" {}

data "azuread_service_principal" "web_app" {
  application_id = "abfa0a7c-a6b6-4736-8310-5855508787cd"
}

resource "azurerm_key_vault" "kv" {
  name                = "kv-${var.project}"
  resource_group_name = var.rg_name
  location            = var.location

  sku_name  = "standard"
  tenant_id = data.azurerm_client_config.current.tenant_id

  soft_delete_retention_days = 7
  purge_protection_enabled   = true
}

resource "azurerm_key_vault_access_policy" "tf" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  certificate_permissions = [
    "Create",
    "Delete",
    "DeleteIssuers",
    "Get",
    "GetIssuers",
    "Import",
    "List",
    "ListIssuers",
    "ManageContacts",
    "ManageIssuers",
    "SetIssuers",
    "Update",
    "Purge"
  ]

  key_permissions = [
    "Backup",
    "Create",
    "Decrypt",
    "Delete",
    "Encrypt",
    "Get",
    "Import",
    "List",
    "Purge",
    "Recover",
    "Restore",
    "Sign",
    "UnwrapKey",
    "Update",
    "Verify",
    "WrapKey",
  ]

  secret_permissions = [
    "Backup",
    "Delete",
    "Get",
    "List",
    "Purge",
    "Recover",
    "Restore",
    "Set",
  ]
}

resource "azurerm_key_vault_access_policy" "webapp" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azuread_service_principal.web_app.object_id

  certificate_permissions = ["Get"]
  secret_permissions      = ["Get"]
}

resource "azurerm_key_vault_certificate" "cert" {
  name         = "acme-cert"
  key_vault_id = azurerm_key_vault.kv.id

  certificate {
    contents = var.wildcard_cert.pfx_value
    password = var.wildcard_cert.pfx_password
  }

  depends_on = [azurerm_key_vault_access_policy.tf]
}

# Single wildcard App Service for all App Services
resource "azurerm_app_service_certificate" "acme" {
  name                = "acme-cert"
  resource_group_name = var.rg_name
  location            = var.location
  key_vault_secret_id = azurerm_key_vault_certificate.cert.secret_id
}
