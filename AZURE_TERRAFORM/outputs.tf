output "public_ip_address" {
  description = "IP público da VM"
  value       = azurerm_public_ip.public_ip.ip_address
}

output "ssh_command" {
  description = "Comando SSH para acesso"
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.public_ip.ip_address}"
}

output "storage_account_name" {
  value = azurerm_storage_account.sa.name
}

output "fileshare_name" {
  value = azurerm_storage_share.fileshare.name
}
