locals {
  number_of_apps = 5

  endpoints = merge({ for i in range(1, 6) : "app-${i}" => "blob" }, { web = "static_website" })
}
