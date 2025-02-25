terraform {
  required_providers {
    flux = {
      source  = "fluxcd/flux"
      version = "1.5.1"
    }
    github = {
      source  = "integrations/github"
      version = "6.5.0"
    }
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.72.0"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.7.1"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.6"
    }
  }

  required_version = "1.10.5"
}

provider "flux" {
  kubernetes = {
    host                   = talos_cluster_kubeconfig.kubeconfig.kubernetes_client_configuration.host
    client_certificate     = base64decode(talos_cluster_kubeconfig.kubeconfig.kubernetes_client_configuration.client_certificate)
    client_key             = base64decode(talos_cluster_kubeconfig.kubeconfig.kubernetes_client_configuration.client_key)
    cluster_ca_certificate = base64decode(talos_cluster_kubeconfig.kubeconfig.kubernetes_client_configuration.ca_certificate)
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
