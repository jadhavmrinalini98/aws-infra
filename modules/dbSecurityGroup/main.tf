resource "aws_security_group" "database" {
  name        = "database"
  description = "Allow access to database"
  vpc_id      = var.vpc_id

  ingress {
    description     = "MySQL"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [var.secGroupId]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

output "db_sec_group_id" {
  value = aws_security_group.database.id
}