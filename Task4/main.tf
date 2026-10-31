terraform {
  required_version = ">= 1.5.0"

  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "= 0.239.0"
    }
  }
}

provider "yandex" {
  service_account_key_file = "C:/Users/kboly/Downloads/authorized_key.json"
  cloud_id                 = "b1g4g0e46sqfa0ivo05h"
  folder_id                = "b1gpg6iesfld6aej69ka"
  zone = var.zone
}

data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2404-lts"
}

locals {
  labels = {
    project     = "future2"
    environment = "lab"
    managed_by  = "terraform"
  }
}

resource "yandex_vpc_network" "main" {
  name   = "${var.prefix}-network"
  labels = local.labels
}

resource "yandex_vpc_gateway" "egress" {
  name = "${var.prefix}-egress-gateway"
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "private" {
  name       = "${var.prefix}-private-routes"
  network_id = yandex_vpc_network.main.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.egress.id
  }
}

resource "yandex_vpc_subnet" "edge" {
  name           = "${var.prefix}-edge-a"
  zone           = var.zone
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = [var.edge_cidr]
}

resource "yandex_vpc_subnet" "app" {
  name           = "${var.prefix}-app-a"
  zone           = var.zone
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = [var.app_cidr]
  route_table_id = yandex_vpc_route_table.private.id
}

resource "yandex_vpc_subnet" "data" {
  name           = "${var.prefix}-data-a"
  zone           = var.zone
  network_id     = yandex_vpc_network.main.id
  v4_cidr_blocks = [var.data_cidr]
  route_table_id = yandex_vpc_route_table.private.id
}

resource "yandex_vpc_security_group" "bastion" {
  name       = "${var.prefix}-bastion-sg"
  network_id = yandex_vpc_network.main.id

  ingress {
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = [var.admin_cidr]
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "portal" {
  name       = "${var.prefix}-portal-sg"
  network_id = yandex_vpc_network.main.id

  ingress {
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = [var.edge_cidr]
  }

  ingress {
    protocol       = "TCP"
    port           = 8080
    v4_cidr_blocks = [var.edge_cidr]
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "analytics" {
  name       = "${var.prefix}-analytics-sg"
  network_id = yandex_vpc_network.main.id

  ingress {
    protocol       = "TCP"
    port           = 22
    v4_cidr_blocks = [var.edge_cidr]
  }

  ingress {
    protocol       = "TCP"
    port           = 8123
    v4_cidr_blocks = [var.app_cidr]
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# 4. Bastion (only public VM)
resource "yandex_compute_instance" "bastion" {
  name                      = "${var.prefix}-bastion"
  zone                      = var.zone
  platform_id               = "standard-v3"
  allow_stopping_for_update = true
  labels                    = local.labels

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 100
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      type     = "network-ssd"
      size     = var.bastion_disk_gb
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.edge.id
    nat                = true
    security_group_ids = [yandex_vpc_security_group.bastion.id]
  }

  metadata = {
    "ssh-keys" = "${var.ssh_user}:${trimspace(file(pathexpand(var.ssh_public_key_path)))}"
  }
}

resource "yandex_compute_instance" "portal" {
  name                      = "${var.prefix}-portal"
  zone                      = var.zone
  platform_id               = "standard-v3"
  allow_stopping_for_update = true
  labels                    = local.labels

  resources {
    cores         = 2
    memory        = 4
    core_fraction = 100
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      type     = "network-ssd"
      size     = var.portal_disk_gb
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.app.id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.portal.id]
  }

  metadata = {
    "ssh-keys" = "${var.ssh_user}:${trimspace(file(pathexpand(var.ssh_public_key_path)))}"
  }
}

resource "yandex_compute_disk" "analytics_data" {
  name   = "${var.prefix}-analytics-data"
  zone   = var.zone
  type   = "network-ssd"
  size   = var.analytics_data_disk_gb
  labels = local.labels
}

resource "yandex_compute_instance" "analytics" {
  name                      = "${var.prefix}-analytics"
  zone                      = var.zone
  platform_id               = "standard-v3"
  allow_stopping_for_update = true
  labels                    = local.labels

  resources {
    cores         = 4
    memory        = 8
    core_fraction = 100
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.id
      type     = "network-ssd"
      size     = var.analytics_boot_disk_gb
    }
  }

  secondary_disk {
    disk_id     = yandex_compute_disk.analytics_data.id
    auto_delete = false
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.data.id
    nat                = false
    security_group_ids = [yandex_vpc_security_group.analytics.id]
  }

  metadata = {
    "ssh-keys" = "${var.ssh_user}:${trimspace(file(pathexpand(var.ssh_public_key_path)))}"
  }
}
