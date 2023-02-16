# aws-infra

INTRODUCTION

Configuration creates set of VPC resources in Dev and Demo environment.

STEPS TO RUN TERRAFORM

$ terraform init
$ terraform plan
$ terraform apply
$ terraform destroy

REQUIREMENTS    

terraform      >= 0.12.26
aws            >= 3.15

PROVIDERS

aws            >= 3.15


MODULES

vpc_cidr_block
vpc_instance_tenancy
vpc_name
vpc_internet_gateway_name
vpc_public_subnet_name
vpc_public_rt_name


RESOURCES 

aws_vpc
aws_internet_gateway
aws_subnet
aws_route_table
aws_route_table_association


AWS Custom VPC Creation steps 

•	Select the region 
•	Create VPC
•	Enable the DNS HOST name in the VPC
•	Create Internet Gateway
•	Attach Internet gateway to the VPC.
•	Create Public Subnets
•	Enable Auto Assign Public IP settings.
•	Create Public route table
•	Add public route to the public route table
•	Associate the Public subnets with the Public Route table
•	Create the Private subnets
•	Create Private Route table 
•	Add public route to the Private route table
•	Associate the Private Subnets with the Private Route table





