output "redis_endpoint" {
  value = aws_elasticache_serverless_cache.redis.endpoint[0].address
}

output "redis_port" {
  value = aws_elasticache_serverless_cache.redis.endpoint[0].port
}
