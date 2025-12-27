variable "location" {
  description = "Região do Azure"
  type        = string
}

variable "resource_group_name" {
  description = "Nome do Resource Group"
  type        = string
}

variable "vm_name" {
  description = "Nome da máquina virtual"
  type        = string
}

variable "admin_username" {
  description = "Usuário administrador da VM"
  type        = string
}

variable "ssh_public_key_path" {
  description = "Caminho para a chave pública SSH"
  type        = string
}

variable "vm_size" {
  description = "SKU da VM"
  type        = string
}

variable "fileshare_name" {
  type    = string
  default = "megsi-fileshare"
}

variable "fileshare_quota_gb" {
  type    = number
  default = 50
}
