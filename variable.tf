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

variable "proxmox_endpoint" {
  type      = string
  sensitive = true
}

variable "proxmox_password" {
  type      = string
  sensitive = true
}

variable "proxmox_token" {
  type      = string
  sensitive = true
}

variable "proxmox_username" {
  type      = string
  sensitive = true
}
