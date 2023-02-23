resource "aws_instance" "app_server" {
  count = var.subnet_count

  ami             = var.ami_id
  instance_type   = var.instance_type
  key_name        = var.ami_key_pair_name
  security_groups = ["${var.sec_id}"]

  tags = {
    Name = "EC2-${count.index + 1}"
  }

  root_block_device {
    volume_size = var.volume_size
    volume_type = var.volume_type
  }

  subnet_id = var.subnet_ids[count.index]
}