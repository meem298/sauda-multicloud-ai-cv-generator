locals {
  common_tags = {
    Project     = "sauda"
    Environment = "prod"
    ManagedBy   = "terraform"
  }
  common_labels = {
    project     = "sauda"
    environment = "prod"
    managed_by  = "terraform"
  }
}

# ════════════════════════════════════════════════════════════════════════════
# AWS STACK
# ════════════════════════════════════════════════════════════════════════════

module "aws_security" {
  source     = "../../modules/aws/security"
  project    = "sauda"
  aws_region = var.aws_region
  vpc_id     = module.aws_vpc.vpc_id
  tags       = local.common_tags
}

module "aws_database" {
  source      = "../../modules/aws/database"
  project     = "sauda"
  environment = "prod"
  tags        = local.common_tags
}

module "aws_storage" {
  source      = "../../modules/aws/storage"
  project     = "sauda"
  environment = "prod"

  enable_versioning           = true
  pdf_expiry_days             = 30
  cloudfront_distribution_arn = module.aws_cdn.cloudfront_distribution_arn
  tags                        = local.common_tags
}

module "aws_compute" {
  source      = "../../modules/aws/compute"
  project     = "sauda"
  environment = "prod"
  aws_region  = var.aws_region

  vpc_id                 = module.aws_vpc.vpc_id
  public_subnet_ids      = module.aws_vpc.public_subnet_ids
  private_subnet_ids     = module.aws_vpc.private_subnet_ids
  sg_alb_id              = module.aws_security.sg_alb_id
  sg_ecs_id              = module.aws_security.sg_ecs_id
  ecs_task_role_arn      = module.aws_security.ecs_task_role_arn
  ecs_execution_role_arn = module.aws_security.ecs_execution_role_arn
  jwt_secret_arn         = module.aws_security.jwt_secret_arn
  vertex_ai_key_arn      = module.aws_security.vertex_ai_key_arn
  pdf_bucket_name        = module.aws_storage.pdfs_bucket_id
  dynamodb_table_name    = module.aws_database.table_name
  sessions_table_name    = module.aws_database.sessions_table_name
  acm_certificate_arn    = var.acm_certificate_arn

  task_cpu                   = 512
  task_memory                = 1024
  desired_count              = 2
  min_capacity               = 1
  max_capacity               = 10
  image_tag                  = var.image_tag
  enable_deletion_protection = true

  log_retention_days = 90
  tags               = local.common_tags
}

module "aws_cdn" {
  source      = "../../modules/aws/cdn"
  project     = "sauda"
  environment = "prod"

  frontend_bucket_regional_domain = module.aws_storage.frontend_bucket_regional_domain
  alb_domain_name                 = module.aws_compute.alb_dns_name
  domain                          = var.domain
  acm_certificate_arn             = var.acm_certificate_arn
  waf_rate_limit                  = 500
  tags                            = local.common_tags

  providers = {
    aws.us_east_1 = aws.us_east_1
  }
}

module "aws_vpc" {
  source     = "../../modules/aws/vpc"
  project    = "sauda"
  aws_region = var.aws_region

  enable_nat_gateway = true
  log_retention_days = 90
  tags               = local.common_tags
}

module "aws_monitoring" {
  source     = "../../modules/aws/monitoring"
  project    = "sauda"
  aws_region = var.aws_region

  log_retention_days      = 90
  ecs_cluster_name        = module.aws_compute.ecs_cluster_name
  ecs_service_name        = module.aws_compute.ecs_service_name
  alb_arn_suffix          = module.aws_compute.alb_arn_suffix
  target_group_arn_suffix = module.aws_compute.target_group_arn_suffix
  alarm_actions           = var.sns_alarm_arns
  tags                    = local.common_tags
}

module "aws_dns" {
  source  = "../../modules/aws/dns"
  project = "sauda"

  domain                    = var.domain
  alb_dns_name              = module.aws_cdn.cloudfront_domain_name
  cloudfront_domain_name    = module.aws_cdn.cloudfront_domain_name
  cloudfront_hosted_zone_id = module.aws_cdn.cloudfront_hosted_zone_id
  gcp_lb_ip                 = module.gcp_compute.cloudrun_hostname
  tags                      = local.common_tags
}

# ════════════════════════════════════════════════════════════════════════════
# GCP STACK
# ════════════════════════════════════════════════════════════════════════════

module "gcp_network" {
  source     = "../../modules/gcp/network"
  project    = "sauda"
  project_id = var.gcp_project_id
  region     = var.gcp_region

  enable_cloud_nat = false
  labels           = local.common_labels
}

module "gcp_security" {
  source     = "../../modules/gcp/security"
  project    = "sauda"
  project_id = var.gcp_project_id

  rate_limit_count = 500
  labels           = local.common_labels
}

module "gcp_storage" {
  source      = "../../modules/gcp/storage"
  project     = "sauda"
  project_id  = var.gcp_project_id
  environment = "prod"

  location          = "US"
  enable_versioning = true
  pdf_expiry_days   = 30
  labels            = local.common_labels
}

module "gcp_firestore" {
  source      = "../../modules/gcp/firestore"
  project_id  = var.gcp_project_id
  environment = "prod"
  location    = "nam5"
  labels      = local.common_labels
}

module "gcp_compute" {
  source      = "../../modules/gcp/compute"
  project     = "sauda"
  project_id  = var.gcp_project_id
  region      = var.gcp_region
  environment = "prod"

  cloudrun_sa_email       = module.gcp_security.cloudrun_sa_email
  jwt_secret_id           = module.gcp_security.jwt_secret_id
  vertex_ai_key_secret_id = module.gcp_security.vertex_ai_key_secret_id
  firestore_database_name = module.gcp_firestore.database_name

  min_instances        = 1
  max_instances        = 20
  cpu                  = "2"
  memory               = "1Gi"
  cpu_always_allocated = true
  labels               = local.common_labels
}

module "gcp_monitoring" {
  source     = "../../modules/gcp/monitoring"
  project    = "sauda"
  project_id = var.gcp_project_id

  cloudrun_domain          = module.gcp_compute.cloudrun_hostname
  notification_channel_ids = []
  alert_email              = var.alert_email
  labels                   = local.common_labels
}
