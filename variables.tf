variable "region" {
  default = "us-east-1"
}

variable "environment" {
  default = "dev"
}

variable "vpc_cidr_block" {
  default = "10.0.0.0/16"
}

variable "vpc_instance_tenancy" {
  default = "default"
}

variable "subnet_count" {
  default = 3
}

variable "subnet_bits" {
  default = 8
}

variable "vpc_name" {
  default = "vpc1"
}

variable "vpc_internet_gateway_name" {
  default = "vpc1IG"
}

variable "vpc_public_subnet_name" {
  default = "vpc1PublicSubnet"
}

variable "vpc_public_rt_name" {
  default = "vpc1PublicRT"
}

variable "vpc_private_subnet_name" {
  default = "vpc1PrivateSubnet"
}

variable "vpc_private_rt_name" {
  default = "vpc1PrivateRT"
}