variable "ami_id" {
  type = string
}

variable "ami_key_pair_name" {
  type = string
}

variable "ec2_profile_name" {
  type = string
}

variable "sec_id" {
  type = string
}

variable "subnet_ids" {
  type = list(any)
}

variable "app_port" {
  type = number
}

variable "vpc_id" {
  type = string
}

variable "zone_id" {
  type = string
}

variable "username" {
  type = string
}
variable "password" {
  type = string
}
variable "db_name" {
  type = string
}

variable "host_name" {
  type = string
}

variable "db_port" {
  type = number
}

variable "s3_bucket" {
  type = string
}

variable "rec_name" {
  type = string
}

variable "lb_sec_id" {
  type = string
}