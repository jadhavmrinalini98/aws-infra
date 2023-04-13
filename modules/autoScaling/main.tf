
resource "aws_kms_key" "kms_key" {
  description              = "KMS Key"
  deletion_window_in_days  = 10
  customer_master_key_spec = "SYMMETRIC_DEFAULT"
}

data "aws_caller_identity" "current" {}

resource "aws_kms_key_policy" "example" {
  key_id = aws_kms_key.kms_key.id
  policy = jsonencode({
    "Id" : "key-consolepolicy-3",
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Sid" : "Enable IAM User Permissions",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        },
        "Action" : "kms:*",
        "Resource" : "*"
      },
      {
        "Sid" : "Allow access for Key Administrators",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : [
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/elasticloadbalancing.amazonaws.com/AWSServiceRoleForElasticLoadBalancing",
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
          ]
        },
        "Action" : [
          "kms:Create*",
          "kms:Describe*",
          "kms:Enable*",
          "kms:List*",
          "kms:Put*",
          "kms:Update*",
          "kms:Revoke*",
          "kms:Disable*",
          "kms:Get*",
          "kms:Delete*",
          "kms:TagResource",
          "kms:UntagResource",
          "kms:ScheduleKeyDeletion",
          "kms:CancelKeyDeletion"
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "Allow use of the key",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : [
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/elasticloadbalancing.amazonaws.com/AWSServiceRoleForElasticLoadBalancing",
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
          ]
        },
        "Action" : [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ],
        "Resource" : "*"
      },
      {
        "Sid" : "Allow attachment of persistent resources",
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : [
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/elasticloadbalancing.amazonaws.com/AWSServiceRoleForElasticLoadBalancing",
            "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/aws-service-role/autoscaling.amazonaws.com/AWSServiceRoleForAutoScaling"
          ]
        },
        "Action" : [
          "kms:CreateGrant",
          "kms:ListGrants",
          "kms:RevokeGrant"
        ],
        "Resource" : "*",
        "Condition" : {
          "Bool" : {
            "kms:GrantIsForAWSResource" : "true"
          }
        }
      }
    ]
  })
}
data "template_file" "user_data" {

  template = <<EOF
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

    systemctl enable amazon-cloudwatch-agent.service 

    sudo ../../../opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
        -a fetch-config \
        -m ec2 \
        -c file:./cloudwatch/cloudwatch-config.json \
        -s
    EOF

}

data "aws_ami" "latest_ami" {
  most_recent = true
  owners      = ["325191631035"]
  filter {
    name   = "name"
    values = ["csye6225_*"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
resource "aws_launch_template" "app_launch_config" {
  user_data     = base64encode(data.template_file.user_data.rendered)
  image_id      = data.aws_ami.latest_ami.id
  instance_type = "t2.micro"
  key_name      = var.ami_key_pair_name
  name          = "launch_template"

  iam_instance_profile {
    name = var.ec2_profile_name
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      delete_on_termination = true
      encrypted             = true
      kms_key_id            = aws_kms_key.kms_key.arn
    }
  }

  network_interfaces {
    associate_public_ip_address = true
    security_groups             = [var.sec_id]
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name = "EC2-${var.ami_id}"
    }
  }
}

resource "aws_lb" "webapplb" {
  name                       = "webapplb"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [var.lb_sec_id]
  subnets                    = var.subnet_ids
  enable_deletion_protection = false
  tags = {
    Application = "WebApp"
  }

}

resource "aws_lb_listener" "webapp_listener" {
  load_balancer_arn = aws_lb.webapplb.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.awslb_tg.arn
  }
  certificate_arn = "arn:aws:acm:us-east-1:448698978168:certificate/0f9a5410-cc61-4f65-932f-75e607d5244e"
}

# resource "aws_lb_listener_certificate" "example" {
#   listener_arn    = aws_lb_listener.webapp_listener.arn
#   certificate_arn = "arn:aws:acm:us-east-1:680696435068:certificate/1c1c9bae-9828-419f-b2bd-ffc5f09aebcd"
# }

resource "aws_lb_target_group" "awslb_tg" {
  name        = "csye6225-lb-alb-tg"
  target_type = "instance"
  port        = var.app_port
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  health_check {
    path = "/healthz"
  }
}

resource "aws_autoscaling_attachment" "autoscaleattach" {
  autoscaling_group_name = aws_autoscaling_group.asg.id
  lb_target_group_arn    = aws_lb_target_group.awslb_tg.arn
}

resource "aws_autoscaling_group" "asg" {

  name                = "asg_launch_config"
  vpc_zone_identifier = var.subnet_ids
  max_size            = 3
  min_size            = 1
  desired_capacity    = 1
  default_cooldown    = 60
  # launch_configuration = aws_launch_template.app_launch_config.name
  launch_template {
    id      = aws_launch_template.app_launch_config.id
    version = "$Latest"
  }

  tag {
    key                 = "name"
    value               = "asg_launch_config"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }

}

resource "aws_autoscaling_policy" "scale_up" {
  name                   = "scale_up"
  cooldown               = 60
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = 1
  policy_type            = "SimpleScaling"
  autoscaling_group_name = aws_autoscaling_group.asg.name
}

resource "aws_autoscaling_policy" "scale_down" {
  name                   = "scale_down"
  cooldown               = 60
  adjustment_type        = "ChangeInCapacity"
  scaling_adjustment     = -1
  policy_type            = "SimpleScaling"
  autoscaling_group_name = aws_autoscaling_group.asg.name
}

resource "aws_cloudwatch_metric_alarm" "scale_down_alarm" {
  alarm_description   = "Monitors High CPU utilization for Web App"
  alarm_actions       = [aws_autoscaling_policy.scale_down.arn]
  alarm_name          = "webapp_scale_down"
  comparison_operator = "LessThanThreshold"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  threshold           = 3
  evaluation_periods  = 1
  period              = 60
  statistic           = "Average"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }
}

resource "aws_cloudwatch_metric_alarm" "scale_up_alarm" {
  alarm_description   = "Monitors Low CPU utilization for Web App"
  alarm_actions       = [aws_autoscaling_policy.scale_up.arn]
  alarm_name          = "webapp_scale_up"
  comparison_operator = "GreaterThanThreshold"
  namespace           = "AWS/EC2"
  metric_name         = "CPUUtilization"
  threshold           = 5
  evaluation_periods  = 1
  period              = 60
  statistic           = "Average"

  dimensions = {
    AutoScalingGroupName = aws_autoscaling_group.asg.name
  }
}

resource "aws_route53_record" "a_record" {
  zone_id = var.zone_id
  name    = var.rec_name
  type    = "A"

  alias {
    name                   = aws_lb.webapplb.dns_name
    zone_id                = aws_lb.webapplb.zone_id
    evaluate_target_health = true
  }
}