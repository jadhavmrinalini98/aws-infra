resource "aws_security_group" "application" {
  name        = "application"
  description = "Allow access to application"
  vpc_id      = var.vpc_id
  ingress {
    description     = "SSH ingress"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [var.lbSecGroupId]
  }
  ingress {
    description     = "Application ingress"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [var.lbSecGroupId]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "sec_group_id" {
  value = aws_security_group.application.id
}