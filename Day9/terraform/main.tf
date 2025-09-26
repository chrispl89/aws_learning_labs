########################################
# Locals & tags
########################################
# Resolve caller's public IPv4 (used if my_ip is empty)
data "http" "me" {
  url = "https://checkip.amazonaws.com/"
}

locals {
  common_tags = {
    Project     = var.project
    Environment = var.environment
    Owner       = "Krzysztof"
    ManagedBy   = "Terraform"
  }
  name_prefix = "${var.project}-${var.environment}"

  # if var.my_ip is non-empty -> use it; otherwise auto-detect and append /32
  effective_my_ip = (
    var.my_ip != null && var.my_ip != "" ?
    var.my_ip :
    "${chomp(data.http.me.response_body)}/32"
  )
}

########################################
# NETWORK (reuse Day7-style module interface)
########################################
module "network" {
  source = "./modules/network"

  # REQUIRED by your module (per error messages)
  project          = var.project
  environment      = var.environment
  vpc_cidr         = var.vpc_cidr
  subnet_cidr      = var.subnet_cidr
  availability_zone = var.availability_zone

  # If your module ALSO supports the “_b” params (check variables.tf),
  # then keep these two lines; otherwise remove them.
  subnet_cidr_b        = var.subnet_cidr_b
  availability_zone_b  = var.availability_zone_b

  # Keep only if the module defines these inputs; if not, remove them.
  name_prefix = local.name_prefix
  common_tags = local.common_tags
}

########################################
# SECURITY
########################################
module "security" {
  source = "./modules/security"

  vpc_id           = module.network.vpc_id
  app_port         = var.app_port
  effective_my_ip  = local.effective_my_ip

  name_prefix = local.name_prefix
  common_tags = local.common_tags
}


########################################
# COMPUTE
########################################
module "compute" {
  source = "./modules/compute"

  vpc_id         = module.network.vpc_id
  subnet_id      = module.network.subnet_a_id
  app_sg_id      = module.security.app_sg_id
  instance_count = var.instance_count
  instance_type  = var.instance_type
  ami_id         = var.ami_id
  ssh_key_name   = var.ssh_key_name
  app_port       = var.app_port

  name_prefix = local.name_prefix
  common_tags = local.common_tags
}

########################################
# ALB
########################################
module "alb" {
  source            = "./modules/alb"
  vpc_id            = module.network.vpc_id
  subnet_ids        = [module.network.subnet_a_id, module.network.subnet_b_id]
  alb_sg_id         = module.security.alb_sg_id
  target_group_name = var.target_group_name
  app_port          = var.app_port
  instance_ids      = module.compute.instance_ids
  name_prefix       = local.name_prefix
  common_tags       = local.common_tags
  alb_name          = var.alb_name
}

########################################
# RDS (Day 9)
########################################

# DB subnet group across two subnets (for the lab we reuse existing subnets)
resource "aws_db_subnet_group" "db" {
  name       = "${local.name_prefix}-db-subnet-group"
  subnet_ids = [module.network.subnet_a_id, module.network.subnet_b_id]

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-db-subnet-group" })
}

# RDS SG: allow DB port only from App SG
resource "aws_security_group" "rds_sg" {
  name        = "${local.name_prefix}-sg-rds"
  description = "Allow DB traffic from App SG only"
  vpc_id      = module.network.vpc_id

  ingress {
    from_port       = var.db_port
    to_port         = var.db_port
    protocol        = "tcp"
    security_groups = [module.security.app_sg_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-sg-rds" })
}

# RDS instance
resource "aws_db_instance" "db" {
  identifier             = "${local.name_prefix}-db"
  engine                 = var.db_engine
  engine_version         = var.db_engine_version
  instance_class         = var.db_instance_class
  db_subnet_group_name   = aws_db_subnet_group.db.name
  vpc_security_group_ids = [aws_security_group.rds_sg.id]

  allocated_storage = var.db_allocated_storage
  storage_type      = "gp2"

  username = var.db_username
  password = var.db_password

  port                = var.db_port
  publicly_accessible = false
  multi_az            = false

  backup_retention_period = 0
  deletion_protection     = false
  skip_final_snapshot     = true

  tags = merge(local.common_tags, { Name = "${local.name_prefix}-rds" })
}
