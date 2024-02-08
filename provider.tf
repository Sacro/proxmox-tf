terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~>0.46.1"
    }
  }
  required_version = "1.7.3"
}

provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_token
  username  = var.proxmox_username
  password  = var.proxmox_password
  # insecure  = true

  ssh {
    agent    = false
    username = var.proxmox_username
    password = var.proxmox_password
  }
}

variable "proxmox_endpoint" {
  type      = string
  sensitive = true
}

variable "proxmox_password" {
  type      = string
  sensitive = true
}

variable "proxmox_token" {
  type      = string
  sensitive = true
}

variable "proxmox_username" {
  type      = string
  sensitive = true
}
