# Configure the AliCloud Provider

variable vpc_cidr_block {}
variable subnet_cidr_block {}
variable region {}
variable env_prefix {}
variable zone_id {}
variable shared_credentials_file {}
variable public_key_location {}
variable instance_type {}

provider "alicloud" {
  region                  = var.region
  shared_credentials_file = var.shared_credentials_file
  profile                 = "default"
}

terraform {
  required_providers {
    alicloud = {
      source  = "aliyun/alicloud"
      version = ">= 1.217.0"
    }
  }
}

data "alicloud_enhanced_nat_available_zones" "default" {}

resource "alicloud_vpc" "myapp-vpc" {
  vpc_name   = "${var.env_prefix}-vpc"
  cidr_block = var.vpc_cidr_block
}

resource "alicloud_vswitch" "myapp-vswitch-1" {
  vpc_id       = alicloud_vpc.myapp-vpc.id
  cidr_block   = var.subnet_cidr_block
  zone_id      = data.alicloud_enhanced_nat_available_zones.default.zones.0.zone_id
  vswitch_name = "${var.env_prefix}-subnet-1"
}

resource "alicloud_nat_gateway" "myapp-gw" {
  vpc_id       = alicloud_vpc.myapp-vpc.id
  network_type = "internet"
  vswitch_id   = alicloud_vswitch.myapp-vswitch-1.id
  nat_type     = "Enhanced"
}

resource "alicloud_route_table" "myapp-route-table" {
  vpc_id           = alicloud_vpc.myapp-vpc.id
  route_table_name = "${var.env_prefix}-rtb"
  associate_type   = "VSwitch"
}

resource "alicloud_route_entry" "myapp-re-1" {
  route_table_id        = alicloud_route_table.myapp-route-table.id
  destination_cidrblock = "0.0.0.0/0"
  nexthop_type          = "NatGateway"
  nexthop_id            = alicloud_nat_gateway.myapp-gw.id
  name                  = "${var.env_prefix}-re-1"
}

resource "alicloud_security_group" "myapp-sg" {
  name = "${var.env_prefix}-sg"
  vpc_id  = alicloud_vpc.myapp-vpc.id
}

resource "alicloud_security_group_rule" "allow_ssh" {
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "22/22"
  security_group_id = alicloud_security_group.myapp-sg.id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "allow_8080" {
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "8080/8080"
  security_group_id = alicloud_security_group.myapp-sg.id
  cidr_ip           = "0.0.0.0/0"
}

resource "alicloud_security_group_rule" "allow_all_egress" {
  type              = "egress"
  ip_protocol       = "all"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "-1/-1"
  security_group_id = alicloud_security_group.myapp-sg.id
  cidr_ip           = "0.0.0.0/0"
}

data "alicloud_images" "latest_image" {
  most_recent = true
  owners = "system"
  name_regex = "^ubuntu_22.*"
}

output "alicloud_image_id" {
  value = data.alicloud_images.latest_image.images.0.id
}

resource "alicloud_key_pair" "ssh-key" {
  key_pair_name = "server-key"
  public_key = file(var.public_key_location)
}

resource "alicloud_instance" "myapp-server" {
  image_id      = data.alicloud_images.latest_image.images.0.id
  instance_type = var.instance_type

  security_groups      = [alicloud_security_group.myapp-sg.id]
  system_disk_category = "cloud_efficiency"
  vswitch_id           = alicloud_vswitch.myapp-vswitch-1.id
  availability_zone    = var.zone_id

  internet_max_bandwidth_out = 3
  key_name                   = alicloud_key_pair.ssh-key.key_pair_name

  user_data = file("entry-script.sh")

  instance_name = "${var.env_prefix}-server"
}

output "ecs_public_ip" {
  value = alicloud_instance.myapp-server.public_ip
}
