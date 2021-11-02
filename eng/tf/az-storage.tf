data "tfe_ip_ranges" "tf_cloud_ips" {}

locals {
  tf_cloud_ips = [
    for ip in data.tfe_ip_ranges.tf_cloud_ips.api :
    replace(ip, "/32", "")
  ]
}

resource "azurerm_storage_account" "static" {
  name                = "stor${replace(var.project, "-", "")}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = var.location

  account_replication_type  = "LRS"
  account_tier              = "Standard"
  allow_blob_public_access  = true
  enable_https_traffic_only = false

  static_website {
    index_document = "index.html"
  }

  network_rules {
    virtual_network_subnet_ids = [azurerm_subnet.appgw.id]
    ip_rules                   = setunion(var.whitelisted_ips, local.tf_cloud_ips)
    default_action             = "Deny"
  }
}

resource "azurerm_storage_blob" "index" {
  name                   = "index.html"
  storage_account_name   = azurerm_storage_account.static.name
  storage_container_name = "$web"

  type           = "Block"
  content_type   = "text/html; charset=utf-8"
  source_content = "<html><body><h1>Hello World !!!</h1></body></html>"
}

output "tf_cloud_ips" {
  value = data.tfe_ip_ranges.tf_cloud_ips.api
}
