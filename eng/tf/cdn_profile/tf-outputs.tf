output "storage_account_name" {
  value = azurerm_storage_account.account.name
}

output "cdn_profile_name" {
  value = azurerm_cdn_profile.profile.name
}
