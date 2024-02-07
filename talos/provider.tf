terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~>0.46.1"
    }
  }

  required_version = "1.7.2"
}
