prefix = "future2-lab"
zone   = "ru-central1-a"

edge_cidr = "10.20.10.0/24"
app_cidr  = "10.20.20.0/24"
data_cidr = "10.20.30.0/24"

admin_cidr = "192.0.2.10/32"

ssh_user            = "ubuntu"
ssh_public_key_path = "~/.ssh/id_ed25519.pub"

bastion_disk_gb        = 20
portal_disk_gb         = 30
analytics_boot_disk_gb = 30
analytics_data_disk_gb = 100
