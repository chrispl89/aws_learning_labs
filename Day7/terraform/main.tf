# auto-detect public IP (http data) - used by security module
data "http" "me" {
  url = "https://checkip.amazonaws.com/"
}

locals {
  effective_my_ip = (
    var.my_ip != null && var.my_ip != "" ?
    var.my_ip :
    "${chomp(data.http.me.response_body)}/32"
  )

  common_tags = {
    Project     = var.project
    Environment = var.environment
    Owner       = "Krzysztof"
    ManagedBy   = "Terraform"
  }

  name_prefix = "${var.project}-${var.environment}"
}

# NETWORK MODULE
module "network" {
  source = "./modules/network"

  project            = var.project
  environment        = var.environment
  vpc_cidr           = var.vpc_cidr
  subnet_cidr        = var.subnet_cidr
  subnet_cidr_b      = var.subnet_cidr_b
  availability_zone  = var.availability_zone
  availability_zone_b= var.availability_zone_b
  common_tags        = local.common_tags
  name_prefix        = local.name_prefix
}

# SECURITY MODULE
module "security" {
  source = "./modules/security"

  vpc_id           = module.network.vpc_id
  effective_my_ip  = local.effective_my_ip
  app_port         = var.app_port
  name_prefix      = local.name_prefix
  common_tags      = local.common_tags
}

# COMPUTE MODULE
module "compute" {
  source = "./modules/compute"

  vpc_id              = module.network.vpc_id
  subnet_id           = module.network.subnet_a_id
  ssh_key_name        = var.ssh_key_name
  ami_id              = var.ami_id
  instance_type       = var.instance_type
  instance_count      = var.instance_count
  app_port            = var.app_port
  app_sg_id           = module.security.app_sg_id
  name_prefix         = local.name_prefix
  common_tags         = local.common_tags
}

# ALB MODULE
module "alb" {
  source = "./modules/alb"

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
