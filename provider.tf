terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~>0.46.1"
    }
  }
  required_version = "1.7.2"
}

provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_token
  insecure  = true
}

variable "proxmox_endpoint" {
  type = string
}

variable "proxmox_token" {
  type = string
}
