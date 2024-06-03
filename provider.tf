terraform {
  required_providers {
    flux = {
      source  = "fluxcd/flux"
      version = "~>1.2.3"
    }
    github = {
      source  = "integrations/github"
      version = "~>5.18.0"
    }
    proxmox = {
      source  = "bpg/proxmox"
      version = "~>0.46.1"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.5"
    }
  }

  required_version = "1.8.4"
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
