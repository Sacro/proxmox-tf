terraform {
  required_providers {
    flux = {
      source  = "fluxcd/flux"
      version = "1.6.4"
    }
    github = {
      source  = "integrations/github"
      version = "6.6.0"
    }
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.83.1"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.9.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.1.0"
    }
  }

  required_version = "1.13.2"
}

provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_token
  username  = var.proxmox_username
  password  = var.proxmox_password
  # insecure  = true

  ssh {
    agent    = false
    username = "root"
    password = var.proxmox_password
  }
}
