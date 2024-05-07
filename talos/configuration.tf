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
    address      = "192.168.15.91"
    dhcp_address = "192.168.15.91"
    }, {
    name         = "talos-fxz-ghr"
    address      = "192.168.15.92"
    dhcp_address = "192.168.15.92"
    }, {
    name         = "talostpi03"
    address      = "192.168.15.93"
    dhcp_address = "192.168.15.93"
    }, {
    name         = "talostpi04"
    address      = "192.168.15.94"
    dhcp_address = "192.168.15.94"
  }])

  # workers = setunion(local.proxmox_workers, local.turingpi_workers)

  domain      = "cluster.benwoodward.cloud"
  gateway     = "192.168.15.254"
  nameservers = ["192.168.15.254"]
  timeservers = ["time.cloudflare.com"]
  subnet      = "24"

  # crane export ghcr.io/siderolabs/extensions:v<talos-version> | tar x -O image-digests | grep <extension-name>
  talos_proxmox_extensions = toset([
    {
      image = "ghcr.io/siderolabs/qemu-guest-agent:8.2.2@sha256:0eb01d83f21d68bd8010b8f2591494b487cf11a397253e68c7d67132520bb47c"
    },
  ])

  # crane export ghcr.io/nberlee/extensions:v<talos-version> | tar x -O image-digests | grep <extension-name>
  talos_turingpi_extensions = toset([
    # {
    #   image = "ghcr.io/nberlee/binfmt-misc:v1.6.7@sha256:2c7bd83188642bfe1a209026bc4f35d736c5d0d1ec34ed73dadb76ecd17e7f81"
    # },
    {
      image = "ghcr.io/nberlee/rk3588:v1.7.1"
    }
  ])

  talos_extensions = toset([
    {
      image = "ghcr.io/siderolabs/binfmt-misc:v1.7.1@sha256:74fd0cf7d9549d7b95b4514264638c492b297a186750079b59bc2510f0c594a3"
    },
    {
      image = "ghcr.io/siderolabs/iscsi-tools:v0.1.4@sha256:4370d0740f27a7ae7aee56a8da6cd4f00ed8019bd4024fa73b44cb388ec86194"
    },
    {
      image = "ghcr.io/siderolabs/tailscale:1.62.1@sha256:83f70e490b1aac16240134a08d099dec8195f9e78db318909028f3b2aa1e2af0"
    },
    {
      image = "ghcr.io/siderolabs/util-linux-tools:2.39.3@sha256:6a0d86f1cfbb296dfe2c29e033d9cb3d9f78ed98413865522238f4e1505365c4"
    },
  ])

  talos_amd64_filename = "nocloud-amd64.raw.xz"
  talos_version        = "v1.7.1"
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
        }]
      }
    }
  }

  talos_config = {
    cluster = {
      externalCloudProvider = {
        enabled = true
        manifests = [
          "https://raw.githubusercontent.com/siderolabs/talos-cloud-controller-manager/main/docs/deploy/cloud-controller-manager.yml",
          # "https://raw.githubusercontent.com/sergelogvinov/proxmox-csi-plugin/main/docs/deploy/proxmox-csi-plugin-talos.yml"
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
      # registries = {
      #   mirrors = {
      #     "docker.io" = {
      #       endpoints    = ["http://harbor/v2/proxy-docker.io"],
      #       overridePath = true
      #     },
      #     "ghcr.io" = {
      #       endpoints    = ["http://harbor/v2/proxy-ghcr.io"]
      #       overridePath = true
      #     },
      #     "gcr.io" = {
      #       endpoints = ["http://harbor/v2/proxy-gcr.io"],
      #       overridePath : true
      #     }
      #     "registry.k8s.io" = {
      #       endpoints = ["http://harbor/v2/proxy-registry.k8s.io"],
      #       overridePath : true
      #     }
      #   }
      # }
      features = {
        hostDNS = {
          enabled = true
          # forwardKubeDNSToHost = true
        }
      }
      kubelet = {
        extraArgs = {
          cloud-provider             = "external"
          rotate-server-certificates = true
        }
      }
      network = {
        nameservers = local.nameservers
      }
      time = {
        servers = local.timeservers
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
          allowedKubernetesNamespaces = [
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
          type        = "bind"
          options = [
            "bind",
            "rshared",
            "rw"
          ]
        }]
      }
      nodeLabels = {
        bgp-policy = "a"
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
