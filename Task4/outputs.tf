output "network_id" {
  description = "VPC ID."
  value       = yandex_vpc_network.main.id
}

output "subnet_ids" {
  value = {
    edge = yandex_vpc_subnet.edge.id
    app  = yandex_vpc_subnet.app.id
    data = yandex_vpc_subnet.data.id
  }
}

output "bastion_public_ip" {
  value = yandex_compute_instance.bastion.network_interface[0].nat_ip_address
}

output "bastion_private_ip" {
  value = yandex_compute_instance.bastion.network_interface[0].ip_address
}

output "portal_private_ip" {
  value = yandex_compute_instance.portal.network_interface[0].ip_address
}

output "analytics_private_ip" {
  value = yandex_compute_instance.analytics.network_interface[0].ip_address
}

output "analytics_data_disk_id" {
  value = yandex_compute_disk.analytics_data.id
}

output "private_nat_gateway_id" {
  value = yandex_vpc_gateway.egress.id
}

output "ssh_jump_example" {
  value = "ssh -J ${var.ssh_user}@${yandex_compute_instance.bastion.network_interface[0].nat_ip_address} ${var.ssh_user}@${yandex_compute_instance.portal.network_interface[0].ip_address}"
}
