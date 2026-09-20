# Production environment: composes the reusable modules in ../../modules.
# Data flows one way:  network -> kms -> eks -> rds -> app

locals {
  name = "${var.project}-${var.environment}"

  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

module "network" {
  source = "../../modules/network"

  name               = local.name
  cluster_name       = local.name
  vpc_cidr           = var.vpc_cidr
  az_count           = var.az_count
  single_nat_gateway = var.single_nat_gateway
}

module "kms" {
  source = "../../modules/kms"

  name = local.name
}

module "eks" {
  source = "../../modules/eks"

  name                 = local.name
  tags                 = local.tags
  kubernetes_version   = var.kubernetes_version
  subnet_ids           = module.network.private_subnet_ids
  kms_key_arn          = module.kms.key_arn
  public_access_cidrs  = var.cluster_public_access_cidrs
  admin_principal_arns = var.admin_principal_arns
  node_instance_types  = var.node_instance_types
  node_min_size        = var.node_min_size
  node_desired_size    = var.node_desired_size
  node_max_size        = var.node_max_size
}

module "rds" {
  source = "../../modules/rds"

  name                      = local.name
  vpc_id                    = module.network.vpc_id
  subnet_ids                = module.network.database_subnet_ids
  allowed_security_group_id = module.eks.cluster_security_group_id
  kms_key_arn               = module.kms.key_arn
  engine_version            = var.db_engine_version
  instance_class            = var.db_instance_class
  allocated_storage         = var.db_allocated_storage
  max_allocated_storage     = var.db_max_allocated_storage
  multi_az                  = var.db_multi_az
  db_name                   = var.db_name
  username                  = var.db_username
  backup_retention_days     = var.db_backup_retention_days
  deletion_protection       = var.db_deletion_protection
}

module "app" {
  source = "../../modules/app"

  name                           = local.name
  region                         = var.region
  namespace                      = var.app_namespace
  oidc_provider_arn              = module.eks.oidc_provider_arn
  oidc_issuer_host               = module.eks.oidc_issuer_host
  kms_key_arn                    = module.kms.key_arn
  db_secret_arn                  = module.rds.secret_arn
  db_address                     = module.rds.address
  db_port                        = module.rds.port
  db_name                        = module.rds.db_name
  external_secrets_chart_version = var.external_secrets_chart_version

  # The in-cluster resources need working nodes and CoreDNS, so wait for the whole eks module.
  depends_on = [module.eks]
}
