
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

        sudo ../../../opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl \
            -a fetch-config \
            -m ec2 \
            -c file:./cloudwatch/cloudwatch-config.json \
            -s
        systemctl start amazon-cloudwatch-agent.service
#       systemctl enable amazon-cloudwatch-agent.service
        
    EOF

}

resource "aws_launch_template" "app_launch_config" {
  user_data     = base64encode(data.template_file.user_data.rendered)
  image_id      = var.ami_id
  instance_type = "t2.micro"
  key_name      = var.ami_key_pair_name

  iam_instance_profile {
    name = var.ec2_profile_name
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

# resource "aws_launch_configuration" "app_launch_config" {
#   image_id                    = var.ami_id
#   instance_type               = "t2.micro"
#   key_name                    = var.ami_key_pair_name
#   associate_public_ip_address = true
#   iam_instance_profile = var.ec2_profile_name
#   security_groups      = [var.sec_id]

#   user_data = <<EOF
#     #!/bin/bash
#     cd /home/ec2-user/webapp
#     echo DBHOST="${var.host_name}" > .env
#     echo DBUSER="${var.username}" >> .env
#     echo DBPASS="${var.password}" >> .env
#     echo DATABASE="${var.db_name}" >> .env
#     echo PORT=${var.app_port} >> .env
#     echo DBPORT=${var.db_port} >> .env
#     echo BUCKETNAME=${var.s3_bucket} >> .env

#     sudo systemctl daemon-reload
#     sudo systemctl start webapp.service
#     sudo systemctl enable webapp.service 

#     systemctl start amazon-cloudwatch-agent.service
#     systemctl enable amazon-cloudwatch-agent.service
#   EOF
# }

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
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.awslb_tg.arn
  }
}

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