variable "github_repository" {
  type = string
}

variable "github_org" {
  type = string
}

variable "github_token" {
  type      = string
  sensitive = true
}

variable "harbor_robot_name" {
  type    = string
  default = "robot$proxy-cache"
}

variable "harbor_robot_token" {
  type      = string
  sensitive = true
}

variable "proxmox_endpoint" {
  type      = string
  sensitive = true
}

variable "proxmox_username" {
  type = string
}

variable "proxmox_password" {
  type      = string
  sensitive = true
}

variable "proxmox_token" {
  type      = string
  sensitive = true
}
