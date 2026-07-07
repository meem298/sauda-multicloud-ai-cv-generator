# JWT Blacklist table — stores revoked tokens until they naturally expire.
# PAY_PER_REQUEST = Always Free tier (25GB + 25 WCU/RCU free monthly).
resource "aws_dynamodb_table" "jwt_blacklist" {
  name         = "${var.project}-jwt-blacklist-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "token_id"

  attribute {
    name = "token_id"
    type = "S"
  }

  # Automatically delete expired tokens — no manual cleanup needed.
  ttl {
    attribute_name = var.ttl_attribute
    enabled        = true
  }

  point_in_time_recovery {
    enabled = false
  }

  server_side_encryption {
    enabled = true
  }

  tags = var.tags
}

# Sessions table — stores conversation state per user.
# TTL auto-deletes sessions after 24h so no manual cleanup is needed.
resource "aws_dynamodb_table" "sessions" {
  name         = "${var.project}-sessions-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "session_id"

  attribute {
    name = "session_id"
    type = "S"
  }

  ttl {
    attribute_name = "expires_at"
    enabled        = true
  }

  server_side_encryption {
    enabled = true
  }

  tags = var.tags
}
