variable "proxmox_server" {
  description = "Server address where Proxmox is installed"
  type        = string
}

variable "proxmox_username" {
  description = "Proxmox API Username, including the realm"
  type        = string
  sensitive   = true
}

variable "proxmox_token" {
  description = "Proxmox API Token"
  type        = string
  sensitive   = true
}
