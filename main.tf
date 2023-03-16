provider "aws" {
  region  = var.region
  profile = var.environment
}

module "vpc_setup" {
  source = "./modules/vpcSetup"

  cidr_block            = var.vpc_cidr_block
  instance_tenancy      = var.vpc_instance_tenancy
  subnet_count          = var.subnet_count
  bits                  = var.subnet_bits
  vpc_name              = var.vpc_name
  internet_gateway_name = var.vpc_internet_gateway_name
  public_subnet_name    = var.vpc_public_subnet_name
  public_rt_name        = var.vpc_public_rt_name
  private_subnet_name   = var.vpc_private_subnet_name
  private_rt_name       = var.vpc_private_rt_name
}

module "sec_group_setup" {
  source = "./modules/securityGroup"

  vpc_id   = module.vpc_setup.vpc_id
  app_port = var.app_port
}

module "db_sec_group_setup" {
  source = "./modules/dbSecurityGroup"

  vpc_id     = module.vpc_setup.vpc_id
  secGroupId = module.sec_group_setup.sec_group_id
}

module "rds_instance" {
  source = "./modules/databaseInstance"

  username           = var.username
  password           = var.password
  engine_version     = var.engine_version
  identifier         = var.identifier
  private_subnet_ids = module.vpc_setup.private_subnet_ids
  security_group_id  = module.db_sec_group_setup.db_sec_group_id
  db_name            = var.db_name
}

module "iam_role_setup" {
  source = "./modules/iamRoleSetup"

  s3_bucket = module.s3_bucket.s3_bucket
}

module "s3_bucket" {
  source = "./modules/s3Bucket"

  environment = var.environment
}

module "instance_create" {
  source = "./modules/instanceCreate"

  ami_id            = var.ami_id
  sec_id            = module.sec_group_setup.sec_group_id
  ami_key_pair_name = var.ami_key_pair_name
  subnet_count      = var.subnet_count
  subnet_ids        = module.vpc_setup.subnet_ids
  volume_size       = var.volume_size
  instance_type     = var.instance_type
  volume_type       = var.volume_type
  db_name           = var.db_name
  username          = var.username
  password          = var.password
  host_name         = module.rds_instance.host_name
  app_port          = var.app_port
  db_port           = var.db_port
  ec2_profile_name  = module.iam_role_setup.ec2_profile_name
  s3_bucket         = module.s3_bucket.s3_bucket
  zone_id           = var.zone_id
  record_name       = var.record_name
}