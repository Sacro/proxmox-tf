locals {
  controlplanes = toset([{
    node    = "proxmox01"
    name    = "taloscp01"
    address = "192.168.15.161"
    }, {
    node    = "proxmox02"
    name    = "taloscp02"
    address = "192.168.15.171"
    }, {
    node    = "proxmox03"
    name    = "taloscp03"
    address = "192.168.15.181"
  }])

  workers = toset([{
    node    = "proxmox01"
    name    = "talosw01"
    address = "192.168.15.211"
    }, {
    node    = "proxmox02"
    name    = "talosw02"
    address = "192.168.15.221"
    }, {
    node    = "proxmox03"
    name    = "talosw03"
    address = "192.168.15.231"
  }])

  domain  = "cluster.benwoodward.cloud"
  gateway = "192.168.15.254"
  subnet  = "24"

  # crane export ghcr.io/siderolabs/extensions:v<talos-version> | tar x -O image-digests | grep <extension-name>
  talos_extensions = toset([{
    image = "ghcr.io/siderolabs/qemu-guest-agent:8.1.3@sha256:426f6c62fba7810c5e73ab251b43d6a5ab68a4066d8bb0b05745905e5f1d61fc"
  }])

  talos_filename = "nocloud-amd64.raw.xz"
  talos_version  = "v1.6.4"
  talos_url      = "https://github.com/siderolabs/talos/releases/download/${local.talos_version}/${local.talos_filename}"

  talos_config = {
    machine = {
      disks = [{
        device = "/dev/sdc"
        partitions : [{
          mountpoint = "/var/mnt"
        }]
      }]
      files = [{
        content = <<-EOT
        [metrics]
          address = "0.0.0.0:11234"
        EOT
        path    = "/etc/cri/conf.d/20-customization.part"
        op      = "create"
      }]
      install = {
        disk       = "/dev/sdb"
        extensions = local.talos_extensions
      }
      kubelet = {
        extraArgs = {
          rotate-server-certificates = true
        }
        extraMounts = [{
          source      = "/var/mnt"
          destination = "/var/mnt"
          type : "bind"
          options : [
            "bind",
            "rshared",
            "rw"
          ]
        }]
      }
      network = {
        nameservers = [
          local.gateway
        ]
      }
      time = {
        servers = [
          local.gateway
        ]
      }

    }
  }

  talos_controlplane_config = {
    cluster = {
      extraManifests = [
        "https://raw.githubusercontent.com/alex1989hu/kubelet-serving-cert-approver/main/deploy/standalone-install.yaml",
        "https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml"
      ]
    }
    machine = {
      network = {
        interfaces = [{
          interface = "eth0"
          vip = {
            ip = local.cluster_vip
          }
        }]
      }
    }
  }

  talos_worker_config = {}

  cluster_endpoint = "https://cluster.benwoodward.cloud:6443"
  cluster_name     = "cluster.benwoodward.cloud"
  cluster_vip      = "192.168.15.150"
}

resource "talos_machine_secrets" "secrets" {
  talos_version = local.talos_version
  lifecycle {
    prevent_destroy = true
  }
}

data "talos_machine_configuration" "control_plane" {
  cluster_endpoint = local.cluster_endpoint
  cluster_name     = local.cluster_name
  machine_secrets  = talos_machine_secrets.secrets.machine_secrets
  machine_type     = "controlplane"
}

data "talos_machine_configuration" "worker" {
  cluster_endpoint = local.cluster_endpoint
  cluster_name     = local.cluster_name
  machine_secrets  = talos_machine_secrets.secrets.machine_secrets
  machine_type     = "worker"
}

data "talos_client_configuration" "client" {
  client_configuration = talos_machine_secrets.secrets.client_configuration
  cluster_name         = local.cluster_name
  endpoints            = setunion([local.cluster_vip], local.controlplanes[*].address)
  nodes                = setunion(local.controlplanes[*].address, local.workers[*].address)
}

resource "tls_private_key" "flux" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

resource "github_repository" "flux" {
  name                 = var.github_repository
  vulnerability_alerts = true
  visibility           = "private"
}

resource "github_branch_protection" "flux" {
  repository_id = github_repository.flux.node_id

  pattern = "main"
  required_pull_request_reviews {
    required_approving_review_count = 2
  }
  require_signed_commits = true
}

resource "github_repository_deploy_key" "flux" {
  depends_on = [github_repository.flux]
  title      = "Flux"
  repository = github_repository.flux.name
  key        = tls_private_key.flux.public_key_openssh
  read_only  = false
}
