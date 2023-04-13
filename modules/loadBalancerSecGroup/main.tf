resource "aws_security_group" "load_balancer" {
  name        = "load balancer"
  description = "Allow access to load balancer"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTPS ingress"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "lb_sec_id" {
  value = aws_security_group.load_balancer.id
}