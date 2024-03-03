# Configure the AliCloud Provider

provider "alicloud" {
  # If not set, cn-beijing will be used.
  region = "cn-shanghai"
}

terraform {
  required_providers {
    alicloud = {
      source  = "aliyun/alicloud"
      version = ">= 1.217.0"
    }
  }
}

variable "name" {
  description = "project name"
}

variable "cidr_blocks" {
  description = "cidr blocks for vpc and subnets"
  type = list(string)
}

data "alicloud_zones" "default" {
  available_disk_category     = "cloud_efficiency"
  available_resource_creation = "VSwitch"
}

resource "alicloud_vpc" "myapp-vpc" {
  vpc_name   = var.name
  cidr_block = var.cidr_blocks[0]
}

resource "alicloud_vswitch" "myapp-vswitch-1" {
  vpc_id       = alicloud_vpc.myapp-vpc.id
  cidr_block   = var.cidr_blocks[1]
  zone_id      = data.alicloud_zones.default.zones.0.id
  vswitch_name = var.name
}
