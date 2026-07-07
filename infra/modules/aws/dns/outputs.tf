output "aws_health_check_id" {
  value = aws_route53_health_check.aws_stack.id
}

output "gcp_health_check_id" {
  value = length(aws_route53_health_check.gcp_stack) > 0 ? aws_route53_health_check.gcp_stack[0].id : ""
}

output "name_servers" {
  description = "Delegate these NS records to your domain registrar"
  value       = var.domain != "" ? aws_route53_zone.main[0].name_servers : []
}

output "hosted_zone_id" {
  value = var.domain != "" ? aws_route53_zone.main[0].zone_id : ""
}
