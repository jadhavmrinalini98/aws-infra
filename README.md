# aws-infra

#INTRODUCTION

Configuration creates set of VPC resources in Dev and Demo environment.

#STEPS TO RUN TERRAFORM

$ terraform init
$ terraform plan
$ terraform apply
$ terraform destroy

#REQUIREMENTS    

terraform      >= 0.12.26
aws            >= 3.15

#PROVIDERS

aws            >= 3.15


#MODULES

vpc_cidr_block
vpc_instance_tenancy
vpc_name
vpc_internet_gateway_name
vpc_public_subnet_name
vpc_public_rt_name


#RESOURCES 

aws_vpc
aws_internet_gateway
aws_subnet
aws_route_table
aws_route_table_association


#AWS Custom VPC Creation steps:

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

    RDS:
    Add DB Security Group and it should be associated with application security group
    Database security group should be attached to this RDS instance
    Create a new parameter group to match your database (Postgres or MySQL) and its version. 
    Then RDS DB instance must use the new parameter group and not the default parameter group.

    Create security groups
    Add ingress and egress rules
    Add ec2 instance variables
    Add DB Security Group and it should be associated with application security group.Database security group should be attached to this RDS instance.
    Create an EC2 security group for your RDS
    Add ingress rule to allow TCP traffic on the port 3306 for MySQL/MariaDB or 5432 for PostgreSQL
    Create a private S3 bucket with a randomly generated bucket name depending on the environment
    Make sure Terraform can delete the bucket even if it is not empty
    Enable default encryption for S3 Bucket
    Create a lifecycle policy for the bucket to transition objects from STANDARD storage class to STANDARD_IA storage class after 30 days.
    
    Create a new parameter group to match your database (Postgres or MySQL) and its version. 
    Then RDS DB instance must use the new parameter group and not the default parameter group.
     
    EC2 instance should be launched with user dataLinks to an external site.
    Database username, password, hostname, and S3 bucket name should be passed to the web application using user dataLinks to an external site.
    The S3 bucket name must be passed to the application via EC2 user data.
    WebAppS3 the policy will allow EC2 instances to perform S3 buckets. This is required for applications on your EC2 instance to talk to the S3 bucket.
    Create an IAM role EC2-CSYE6225 for the EC2 service and attach the WebAppS3 policy to it. You will attach this role to your EC2 instance