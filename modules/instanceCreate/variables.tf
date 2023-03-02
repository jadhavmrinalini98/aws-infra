variable "ami_id" {
  type = string
}

variable "sec_id" {
  type = string
}

variable "ami_key_pair_name" {
  type = string
}

variable "subnet_count" {
  type = number
}

variable "subnet_ids" {
  type = list(any)
}

variable "instance_type" {
  type = string
}

variable "volume_type" {
  type = string
}

variable "volume_size" {
  type = number
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

variable "app_port" {
  type = number
}

variable "host_name" {
  type = string
}

variable "db_port" {
  type = number
}

variable "ec2_profile_name" {
  type = string
}

variable "s3_bucket" {
  type = string
}