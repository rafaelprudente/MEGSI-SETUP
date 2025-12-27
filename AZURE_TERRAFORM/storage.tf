resource "azurerm_storage_account" "sa" {
  name                     = lower(replace("${var.vm_name}sa", "-", ""))
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location

  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"

  min_tls_version          = "TLS1_2"
}

resource "time_sleep" "wait_for_fileservice" {
  depends_on = [
    azurerm_storage_account.sa
  ]

  create_duration = "300s"
}

resource "azurerm_storage_share" "fileshare" {
  name                 = var.fileshare_name
  storage_account_name = azurerm_storage_account.sa.name
  quota                = var.fileshare_quota_gb

  depends_on = [
    time_sleep.wait_for_fileservice
  ]
}
