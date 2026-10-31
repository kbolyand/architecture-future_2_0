variable "prefix" {
  type    = string
  default = "future2-lab"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{2,30}$", var.prefix))
    error_message = "Prefix must begin with a lower-case letter and contain 3..31 lowercase/digit/hyphen characters."
  }
}

variable "zone" {
  type    = string
  default = "ru-central1-a"
}

variable "edge_cidr" {
  type    = string
  default = "10.20.10.0/24"
}

variable "app_cidr" {
  type    = string
  default = "10.20.20.0/24"
}

variable "data_cidr" {
  type    = string
  default = "10.20.30.0/24"
}

variable "admin_cidr" {
  type    = string
  default = "192.0.2.10/32"

  validation {
    condition     = can(cidrhost(var.admin_cidr, 0)) && var.admin_cidr != "0.0.0.0/0"
    error_message = "Provide a valid restricted CIDR, never 0.0.0.0/0."
  }
}

variable "ssh_user" {
  type    = string
  default = "ubuntu"
}

variable "ssh_public_key_path" {
  type    = string
  default = "~/.ssh/id_ed25519.pub"
}

variable "bastion_disk_gb" {
  type    = number
  default = 20
}

variable "portal_disk_gb" {
  type    = number
  default = 30
}

variable "analytics_boot_disk_gb" {
  type    = number
  default = 30
}

variable "analytics_data_disk_gb" {
  type    = number
  default = 100
}
