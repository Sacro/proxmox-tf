terraform {
  required_providers {
    deepmerge = {
      source  = "isometry/deepmerge"
      version = "~> 1.0"
    }
    flux = {
      source  = "fluxcd/flux"
      version = "1.7.6"
    }
    github = {
      source  = "integrations/github"
      version = "6.10.2"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "0.10.1"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.1.0"
    }
  }

  required_version = "1.14.7"
}
