terraform {
  required_providers {
    flux = {
      source  = "fluxcd/flux"
      version = "1.3.0"
    }
    github = {
      source  = "integrations/github"
      version = "6.3.0"
    }
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.65.0"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.6.0-beta.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.6"
    }
  }

  required_version = "1.9.6"
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
