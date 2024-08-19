terraform {
  required_version = ">= 1.9"
  required_providers {
    proxmox = {
      source  = "Telmate/proxmox"
      version = "3.0.1-rc3"
    }
  }
}

provider "proxmox" {
  pm_tls_insecure     = false
  pm_api_url          = "https://${var.proxmox_server}/api2/json"
  pm_api_token_secret = var.proxmox_api_token_secret
  pm_api_token_id     = var.proxmox_api_token_id
}
