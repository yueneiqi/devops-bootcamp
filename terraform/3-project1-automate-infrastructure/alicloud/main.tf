provider "alicloud" {
  region                  = var.region
  shared_credentials_file = var.shared_credentials_file
  profile                 = var.profile
}

resource "alicloud_vpc" "myapp-vpc" {
  vpc_name   = "${var.env_prefix}-vpc"
  cidr_block = var.vpc_cidr_block
}

module "myapp-vswitch" {
  source            = "./modules/vswitch"
  vpc_id            = alicloud_vpc.myapp-vpc.id
  env_prefix        = var.env_prefix  
  subnet_cidr_block = var.subnet_cidr_block
}

module "myapp-server" {
  source              = "./modules/webserver"
  vpc_id              = alicloud_vpc.myapp-vpc.id
  env_prefix          = var.env_prefix  
  image_name_regex    = var.image_name_regex
  public_key_location = var.public_key_location
  instance_type       = var.instance_type
  zone_id             = var.zone_id
  vswitch_id          = module.myapp-vswitch.vswitch.id
}