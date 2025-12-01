terraform {
  required_providers {
    deepmerge = {
      source  = "isometry/deepmerge"
      version = "~> 1.0"
    }
    flux = {
      source  = "fluxcd/flux"
      version = "1.7.5"
    }
    github = {
      source  = "integrations/github"
      version = "6.8.3"
    }
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.88.0"
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

  required_version = "1.14.0"
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
