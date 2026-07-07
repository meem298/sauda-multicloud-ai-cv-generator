resource "aws_elasticache_subnet_group" "main" {
  name       = "${var.project}-redis-subnet-group"
  subnet_ids = var.private_subnet_ids
  tags       = var.tags
}

resource "aws_elasticache_serverless_cache" "redis" {
  engine = "redis"
  name   = "${var.project}-redis-${var.environment}"

  cache_usage_limits {
    data_storage {
      maximum = var.max_data_storage_gb
      unit    = "GB"
    }
    ecpu_per_second {
      maximum = var.max_ecpu_per_second
    }
  }

  subnet_ids         = var.private_subnet_ids
  security_group_ids = [var.sg_redis_id]

  major_engine_version = "7"

  tags = var.tags
}
