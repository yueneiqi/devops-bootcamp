provider "digitalocean" {
  token = var.do_token
}

# data "digitalocean_droplet" "example1" {
#   name = "jenkins-server"
# }

# output "ubuntu" {
#   value = data.digitalocean_droplet.example1
# }

# data "digitalocean_image" "example1" {
#   slug = data.digitalocean_droplet.example1.image
# }

# output "ubuntu-image" {
#   value = data.digitalocean_image.example1
# }

resource "digitalocean_droplet" "jenkins-server" {
  image    = "ubuntu-23-10-x64" # slug
  name     = "jenkins-server"
  region   = "sgp1"
  size     = "s-2vcpu-4gb"
  ssh_keys = var.ssh_keys
}

resource "digitalocean_firewall" "jenkins-server" {
  name = "only-22-and-8080"

  droplet_ids = [digitalocean_droplet.jenkins-server.id]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol         = "tcp"
    port_range       = "8080"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

resource "null_resource" "configure_server" {
  triggers = {
    trigger = digitalocean_droplet.jenkins-server.ipv4_address
  }

  provisioner "local-exec" {
    working_dir = "../ansible"
    command     = "ansible-playbook --inventory ${digitalocean_droplet.jenkins-server.ipv4_address}, --private-key ${var.private_key_location} --user root deploy-docker-and-ansible.yaml"
  }
}