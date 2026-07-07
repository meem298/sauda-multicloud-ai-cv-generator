output "api_endpoint" {
  description = "API Gateway invoke URL (use as CloudFront origin)"
  value       = aws_apigatewayv2_stage.default.invoke_url
}

output "api_id" {
  value = aws_apigatewayv2_api.backend.id
}

output "lambda_function_name" {
  value = aws_lambda_function.backend.function_name
}

output "lambda_function_arn" {
  value = aws_lambda_function.backend.arn
}

# Strip "https://" for use as CloudFront origin domain
output "api_domain" {
  value = trimsuffix(replace(aws_apigatewayv2_stage.default.invoke_url, "https://", ""), "/")
}
