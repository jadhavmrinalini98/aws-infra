resource "aws_db_parameter_group" "parameter_group" {
  name        = "pg-cloud-db"
  family      = "mysql8.0"
  description = "cloud RDS parameter group"
}

resource "aws_db_subnet_group" "subnet_group" {
  name       = "subnet-group"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "My DB subnet group"
  }
}

resource "aws_db_instance" "rds_instance" {
  allocated_storage      = 10
  identifier             = var.identifier
  db_name                = var.db_name
  engine                 = "mysql"
  engine_version         = var.engine_version
  instance_class         = "db.t3.micro"
  username               = var.username
  password               = var.password
  parameter_group_name   = aws_db_parameter_group.parameter_group.name
  skip_final_snapshot    = true
  multi_az               = false
  db_subnet_group_name   = aws_db_subnet_group.subnet_group.name
  vpc_security_group_ids = [var.security_group_id]

  //Set it to false.
  publicly_accessible = false
}

output "host_name" {
  value = aws_db_instance.rds_instance.address
}