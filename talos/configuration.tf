locals {
  proxmox_controlplanes = toset([{
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

  controlplanes = setunion(local.proxmox_controlplanes)

  proxmox_workers = toset([{
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

  turingpi_workers = toset([{
    name         = "talostpi01"
    address      = "192.168.15.32"
    dhcp_address = "192.168.15.32"
    }, {
    name         = "talos-fxz-ghr"
    address      = "192.168.15.34"
    dhcp_address = "192.168.15.34"
    }, {
    name         = "talostpi03"
    address      = "192.168.15.43"
    dhcp_address = "192.168.15.43"
    }, {
    name         = "talostpi04"
    address      = "192.168.15.44"
    dhcp_address = "192.168.15.44"
  }])

  # workers = setunion(local.proxmox_workers, local.turingpi_workers)

  domain  = "cluster.benwoodward.cloud"
  gateway = "192.168.15.254"
  subnet  = "24"

  # crane export ghcr.io/siderolabs/extensions:v<talos-version> | tar x -O image-digests | grep <extension-name>
  talos_proxmox_extensions = toset([
    {
      image = "ghcr.io/siderolabs/binfmt-misc:v1.6.6@sha256:37865e0c2b4f6d15052a0cac5ff331ba4dad7d9beb7e9b8bdb198425f995b04e"
    },
    {
      image = "ghcr.io/siderolabs/qemu-guest-agent:8.1.3@sha256:426f6c62fba7810c5e73ab251b43d6a5ab68a4066d8bb0b05745905e5f1d61fc"
    },
    # {
    #   image = "ghcr.io/siderolabs/tailscale:1.54.0@sha256:bcbeafd1f95053d5b2668f9a486601a24a0f61efaf7fe2cf0da74ef3aaa5b4b2"
    # }
  ])

  # crane export ghcr.io/nberlee/extensions:v<talos-version> | tar x -O image-digests | grep <extension-name>
  talos_turingpi_extensions = toset([
    {
      image = "ghcr.io/nberlee/binfmt-misc:v1.6.6@sha256:943c30097cbfffaebcea86ebdd096fc7e7186998cc3de93827a74078c7251bd4"
    },
    {
      image = "ghcr.io/nberlee/rk3588:v1.6.6@sha256:e31a8ce2d512b0c81122cf4d2e79337c866848962049dbfef070420777a8fbd3"
    }
  ])

  talos_extensions = toset([
    {
      image = "ghcr.io/siderolabs/iscsi-tools:v0.1.4@sha256:7a775b029140e9f7c0bcecd5f31ebe2f4a6bfbfa6e1976bd8334a885b76862ba"
    },
    {
      image = "ghcr.io/siderolabs/util-linux-tools:v1.6.6@sha256:76b0a6f1800e1430d7fd90fddb38d814386580d49d75bacad4d2fd4ba188d435"
    }
  ])

  talos_amd64_filename = "nocloud-amd64.raw.xz"
  talos_version        = "v1.6.6"
  talos_amd64_url      = "https://github.com/siderolabs/talos/releases/download/${local.talos_version}/${local.talos_amd64_filename}"

  talos_proxmox_controlplane_config = {
    machine = {
      install = {
        disk       = "/dev/sdb"
        extensions = local.talos_proxmox_extensions
      }
    }
  }

  talos_proxmox_worker_config = {
    machine = {
      install = {
        disk       = "/dev/sdc"
        extensions = setunion(local.talos_extensions, local.talos_proxmox_extensions)
      }
      disks = [{
        device = "/dev/sdb"
        partitions = [{
          mountpoint = "/var/lib/longhorn"
        }]
      }]
    }
  }

  talos_turingpi_worker_config = {
    machine = {
      disks = [{
        device = "/dev/nvme0n1"
        partitions = [{
          mountpoint = "/var/lib/longhorn"
        }]
      }]
      install = {
        disk       = "/dev/mmcblk0"
        extensions = setunion(local.talos_extensions, local.talos_turingpi_extensions)
      }
      kernel = {
        modules = [{
          name = "rockchip-cpufreq"
          }
        ]
      }
    }
  }

  talos_config = {
    cluster = {
      externalCloudProvider = {
        enabled = true
        manifests = [
          "https://raw.githubusercontent.com/siderolabs/talos-cloud-controller-manager/main/docs/deploy/cloud-controller-manager.yml",
          "https://raw.githubusercontent.com/sergelogvinov/proxmox-csi-plugin/main/docs/deploy/proxmox-csi-plugin-talos.yml"
        ]
      }
      network = {
        cni = {
          name = "none"
        }
      }
      proxy = {
        disabled = true
      }
    }
    machine = {
      files = [{
        content = <<-EOT
        [metrics]
          address = "0.0.0.0:11234"
        EOT
        path    = "/etc/cri/conf.d/20-customization.part"
        op      = "create"
      }]
      kubelet = {
        extraArgs = {
          cloud-provider : "external"
          rotate-server-certificates = true
        }
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
      inlineManifests = [{
        name     = "cilium"
        contents = templatefile("${path.module}/cilium.yaml", {})
      }]
    }
    machine = {
      features = {
        kubePrism = {
          enabled = true,
          port    = 7445
        }
        kubernetesTalosAPIAccess = {
          enabled = true,
          allowedRoles = [
            "os:reader"
          ]
          allowedKubernetesNamespaces : [
            "kube-system"
          ]
        }
      }
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

  talos_worker_config = {
    machine = {
      kubelet = {
        extraMounts = [{
          source      = "/var/lib/longhorn"
          destination = "/var/lib/longhorn"
          type : "bind"
          options : [
            "bind",
            "rshared",
            "rw"
          ]
        }]
      }
    }
  }

  cluster_endpoint = "https://cluster.benwoodward.cloud:6443"
  cluster_name     = "cluster.benwoodward.cloud"
  cluster_vip      = "192.168.15.150"
}

resource "talos_machine_secrets" "secrets" {
  talos_version = local.talos_version
  lifecycle {
    prevent_destroy = true
    ignore_changes = [
      talos_version
    ]
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
  nodes                = setunion(local.proxmox_controlplanes[*].address, local.proxmox_workers[*].address)
}

resource "tls_private_key" "flux" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
  lifecycle {
    prevent_destroy = true
  }
}

resource "github_repository" "flux" {
  name                 = var.github_repository
  vulnerability_alerts = true
  visibility           = "public"
  lifecycle {
    prevent_destroy = true
  }
}

resource "github_branch_protection" "flux" {
  repository_id = github_repository.flux.node_id

  pattern = "main"
  required_pull_request_reviews {
    required_approving_review_count = 2
  }
  require_signed_commits = true
  lifecycle {
    prevent_destroy = true
  }
}

resource "github_repository_deploy_key" "flux" {
  depends_on = [github_repository.flux]
  title      = "Flux"
  repository = github_repository.flux.name
  key        = tls_private_key.flux.public_key_openssh
  read_only  = false
  lifecycle {
    prevent_destroy = true
  }
}
