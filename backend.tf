terraform {
  backend "http" {
    address        = "https://api.tfstate.dev/github/v1"
    lock_address   = "https://api.tfstate.dev/github/v1/lock"
    unlock_address = "https://api.tfstate.dev/github/v1/lock"
    lock_method    = "PUT"
    unlock_method  = "DELETE"
    username       = "Sacro/proxmox-tf"
  }
}

# tflint-ignore: terraform_unused_declarations
data "terraform_remote_state" "state" {
  backend = "http"

  config = {
    address  = "https://api.tfstate.dev/github/v1"
    username = "Sacro/proxmox-tf"
    password = var.github_token
  }
}

variable "github_token" {
  type = string
}
