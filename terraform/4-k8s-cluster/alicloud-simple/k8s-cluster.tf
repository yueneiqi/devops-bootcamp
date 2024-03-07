provider "alicloud" {
  region                  = var.region
  shared_credentials_file = var.shared_credentials_file
  profile                 = "default"
}

module "managed-k8s" {
  source = "terraform-alicloud-modules/managed-kubernetes/alicloud"

  k8s_name_prefix = "my-managed-k8s-with-new-vpc"
  cluster_spec    = "ack.pro.small"
  new_vpc         = true
  vpc_cidr        = var.vpc_cidr_block
  vswitch_cidrs   = var.vswitch_cidr_blocks
}