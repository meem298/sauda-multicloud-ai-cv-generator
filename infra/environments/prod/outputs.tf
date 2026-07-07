output "aws_cloudfront_url" {
  value = "https://${module.aws_cdn.cloudfront_domain_name}"
}

output "cloudfront_domain_name" {
  value = module.aws_cdn.cloudfront_domain_name
}

output "alb_dns_name" {
  value = module.aws_compute.alb_dns_name
}

output "ecr_repository_url" {
  value = module.aws_compute.ecr_repository_url
}

output "ecs_cluster_name" {
  value = module.aws_compute.ecs_cluster_name
}

output "ecs_service_name" {
  value = module.aws_compute.ecs_service_name
}

output "gcp_cloudrun_url" {
  value = module.gcp_compute.cloudrun_hostname
}

output "route53_name_servers" {
  description = "Delegate these to your domain registrar"
  value       = module.aws_dns.name_servers
}
