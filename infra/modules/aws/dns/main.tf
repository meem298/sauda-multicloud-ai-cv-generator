# ── Route 53 Health Checks ────────────────────────────────────────────────────
resource "aws_route53_health_check" "aws_stack" {
  fqdn              = var.alb_dns_name
  port              = 443
  type              = "HTTPS"
  resource_path     = "/health"
  failure_threshold = 3
  request_interval  = 10

  tags = merge(var.tags, { Name = "${var.project}-hc-aws" })
}

resource "aws_route53_health_check" "gcp_stack" {
  count             = var.gcp_lb_ip != "" ? 1 : 0
  fqdn              = var.gcp_lb_ip
  port              = 443
  type              = "HTTPS"
  resource_path     = "/health"
  failure_threshold = 3
  request_interval  = 10

  tags = merge(var.tags, { Name = "${var.project}-hc-gcp" })
}

# ── Hosted Zone & Weighted Records (only if domain is provided) ───────────────
resource "aws_route53_zone" "main" {
  count = var.domain != "" ? 1 : 0
  name  = var.domain
  tags  = var.tags
}

resource "aws_route53_record" "aws_weighted" {
  count          = var.domain != "" ? 1 : 0
  zone_id        = aws_route53_zone.main[0].zone_id
  name           = var.domain
  type           = "A"
  set_identifier = "aws-primary"

  weighted_routing_policy {
    weight = 60
  }

  health_check_id = aws_route53_health_check.aws_stack.id

  alias {
    name                   = var.cloudfront_domain_name
    zone_id                = var.cloudfront_hosted_zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "gcp_weighted" {
  count          = var.domain != "" && var.gcp_lb_ip != "" ? 1 : 0
  zone_id        = aws_route53_zone.main[0].zone_id
  name           = var.domain
  type           = "A"
  set_identifier = "gcp-secondary"
  ttl            = 30

  weighted_routing_policy {
    weight = 40
  }

  health_check_id = aws_route53_health_check.gcp_stack[0].id

  records = [var.gcp_lb_ip]
}
