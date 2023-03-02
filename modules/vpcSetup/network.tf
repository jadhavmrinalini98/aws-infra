resource "aws_vpc" "vpc" {
  cidr_block           = var.cidr_block
  instance_tenancy     = var.instance_tenancy
  enable_dns_hostnames = true
  tags = {
    Name = "${var.vpc_name}"
  }
}

output "vpc_id" {
  value = aws_vpc.vpc.id
}

resource "aws_internet_gateway" "internet-gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.internet_gateway_name}"
  }
}

//-----------Public Subnet----------------

resource "aws_subnet" "public-subnet" {
  count                   = var.subnet_count
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(var.cidr_block, var.bits, count.index + 1)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.public_subnet_name}-${count.index + 1}"
  }
}

output "subnet_ids" {
  value = aws_subnet.public-subnet.*.id
}

resource "aws_route_table" "public-route-table" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet-gateway.id
  }

  tags = {
    Name = "${var.public_rt_name}"
  }
}

resource "aws_route_table_association" "public-subnet-route-table-association" {
  count          = var.subnet_count
  subnet_id      = aws_subnet.public-subnet[count.index].id
  route_table_id = aws_route_table.public-route-table.id
}

//-----------Private Subnet----------------

resource "aws_subnet" "private-subnet" {
  count                   = var.subnet_count
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = cidrsubnet(var.cidr_block, var.bits, (var.subnet_count + 1) + count.index + 1)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.private_subnet_name}-${count.index + 1}"
  }
}

output "private_subnet_ids" {
  value = aws_subnet.private-subnet.*.id
}

resource "aws_route_table" "private-route-table" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = "${var.private_rt_name}"
  }
}

resource "aws_route_table_association" "private-subnet-route-table-association" {
  count          = var.subnet_count
  subnet_id      = aws_subnet.private-subnet[count.index].id
  route_table_id = aws_route_table.private-route-table.id
}

data "aws_availability_zones" "available" {}