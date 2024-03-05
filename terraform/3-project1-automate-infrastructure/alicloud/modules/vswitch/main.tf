data "alicloud_enhanced_nat_available_zones" "default" {}

resource "alicloud_vswitch" "myapp-vswitch-1" {
  vpc_id       = var.vpc_id
  cidr_block   = var.subnet_cidr_block
  zone_id      = data.alicloud_enhanced_nat_available_zones.default.zones.0.zone_id
  vswitch_name = "${var.env_prefix}-subnet-1"
}

resource "alicloud_nat_gateway" "myapp-gw" {
  vpc_id       = var.vpc_id
  network_type = "internet"
  vswitch_id   = alicloud_vswitch.myapp-vswitch-1.id
  nat_type     = "Enhanced"
}

resource "alicloud_route_table" "myapp-route-table" {
  vpc_id           = var.vpc_id
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