resource "aws_instance" "app_server" {
  # count = var.subnet_count

  ami                     = var.ami_id
  instance_type           = var.instance_type
  key_name                = var.ami_key_pair_name
  security_groups         = ["${var.sec_id}"]
  iam_instance_profile    = var.ec2_profile_name
  disable_api_termination = true

  tags = {
    Name = "EC2-${var.ami_id}"
  }

  root_block_device {
    volume_size = var.volume_size
    volume_type = var.volume_type
  }

  user_data = <<EOF
    #!/bin/bash
    cd /home/ec2-user/webapp
    echo DBHOST="${var.host_name}" > .env
    echo DBUSER="${var.username}" >> .env
    echo DBPASS="${var.password}" >> .env
    echo DATABASE="${var.db_name}" >> .env
    echo PORT=${var.app_port} >> .env
    echo DBPORT=${var.db_port} >> .env
    echo BUCKETNAME=${var.s3_bucket} >> .env

    sudo chown -R root:ec2-user /var/log   
    sudo chmod -R 770 -R /var/log

    sudo systemctl daemon-reload
    sudo systemctl start webapp.service
    sudo systemctl enable webapp.service    

    sudo ../../../opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
        -a fetch-config \
        -m ec2 \
        -c file:./cloudwatch/cloudwatch-config.json \
        -s

  EOF

  subnet_id = var.subnet_ids[0]
}

resource "aws_route53_record" "a_record" {
  zone_id = var.zone_id
  name    = var.record_name
  type    = "A"
  ttl     = 60
  records = [aws_instance.app_server.public_ip]
}