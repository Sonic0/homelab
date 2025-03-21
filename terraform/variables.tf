variable "proxmox_url" {
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

variable "ssh_pub_keys" {
  description = "SSH public keys to add to authorized keys file for the cloud-init user"
  type        = string
}

variable "template_name" {
  description = "The base VM from which to clone to create the new VM"
  type        = string
}

variable "k3s_token" {
  description = "K3S token for worker nodes to join the cluster"
  type        = string
  sensitive   = true
}
