data "tfe_ip_ranges" "tf_cloud_ips" {}

locals {
  tf_cloud_ips = [
    for ip in data.tfe_ip_ranges.tf_cloud_ips.api :
    replace(ip, "/32", "")
  ]
}

resource "azurerm_storage_account" "account" {
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location
  name                = "stor${replace(var.project, "-", "")}"

  account_tier              = "Standard"
  account_replication_type  = "LRS"
  allow_blob_public_access  = true
  enable_https_traffic_only = false

  static_website {
    index_document = "index.html"
  }
}

# resource "azurerm_storage_account_network_rules" "storage_rules" {
#   storage_account_id = azurerm_storage_account.account.id

#   virtual_network_subnet_ids = [azurerm_subnet.appgw.id]
#   ip_rules                   = setunion(var.whitelisted_ips, local.tf_cloud_ips, azurerm_app_service.app.outbound_ip_address_list)
#   default_action             = "Deny"
# }

resource "azurerm_storage_blob" "index" {
  name                   = "index.html"
  storage_account_name   = azurerm_storage_account.account.name
  storage_container_name = "$web"

  type         = "Block"
  content_type = "text/html; charset=utf-8"
  source       = "./index.html"
}
