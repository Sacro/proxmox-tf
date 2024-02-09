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
      version = "~>0.4.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.5"
    }
  }

  required_version = "1.7.3"
}

provider "flux" {
  kubernetes = {
    host                   = local.cluster_vip
    client_certificate     = base64decode(data.talos_cluster_kubeconfig.kubeconfig.client_configuration.client_certificate)
    client_key             = base64decode(data.talos_cluster_kubeconfig.kubeconfig.client_configuration.client_key)
    cluster_ca_certificate = base64decode(data.talos_cluster_kubeconfig.kubeconfig.client_configuration.ca_certificate)
  }
  git = {
    url = "ssh://git@github.com/${var.github_org}/${var.github_repository}.git"
    ssh = {
      username    = "git"
      private_key = tls_private_key.flux.private_key_pem
    }
  }
}

provider "github" {
  owner = var.github_org
  token = var.github_token
}
