resource "aws_cognito_user_pool" "kibana" {
  name = "kibana-${var.eks_cluster_name}"
}

resource "aws_cognito_user_pool_domain" "kibana" {
  domain       = "kibana-${var.eks_cluster_name}"
  user_pool_id = aws_cognito_user_pool.kibana.id
}

resource "aws_cognito_user_pool_client" "kibana" {
  name = "kibana"

  user_pool_id = aws_cognito_user_pool.kibana.id
}

output "cognito_user_pool_id" {
  value = aws_cognito_user_pool.kibana.id
}

output "cognito_user_pool_domain" {
  value = aws_cognito_user_pool_domain.kibana.domain
}

output "cognito_user_pool_endpoint" {
  value = aws_cognito_user_pool.kibana.endpoint
}

output "cognito_user_pool_arn" {
  value = aws_cognito_user_pool.kibana.arn
}

output "cognito_user_pool_clientid" {
  value = aws_cognito_user_pool_client.kibana.id
}