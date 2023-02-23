variable "cidr_block" {
  type = string
}

variable "instance_tenancy" {
  type = string
}

variable "subnet_count" {
  type = number
}

variable "bits" {
  type = number
}

variable "vpc_name" {
  type = string
}

variable "internet_gateway_name" {
  type = string
}

variable "public_subnet_name" {
  type = string
}

variable "public_rt_name" {
  type = string
}

variable "private_subnet_name" {
  type = string
}

variable "private_rt_name" {
  type = string
}