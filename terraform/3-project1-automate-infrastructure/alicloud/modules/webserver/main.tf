resource "alicloud_security_group" "myapp-sg" {
  name = "${var.env_prefix}-sg"
  vpc_id  = var.vpc_id
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
  name_regex = var.image_name_regex
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
  vswitch_id           = var.vswitch_id
  availability_zone    = var.zone_id

  internet_max_bandwidth_out = 3
  key_name                   = alicloud_key_pair.ssh-key.key_pair_name

  user_data = file("entry-script.sh")

  instance_name = "${var.env_prefix}-server"
}