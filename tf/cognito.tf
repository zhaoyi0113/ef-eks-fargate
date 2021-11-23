resource "aws_cognito_user_pool" "kibana" {
  name = "kibana-${var.eks_cluster_name}"

  admin_create_user_config {
    allow_admin_create_user_only = true
  }
  password_policy {
    minimum_length = 6
  }
}

resource "aws_cognito_user_pool_domain" "kibana" {
  domain       = "kibana-${var.eks_cluster_name}"
  user_pool_id = aws_cognito_user_pool.kibana.id
}

resource "aws_cognito_user_pool_client" "kibana" {
  name                                 = "kibana"
  generate_secret                      = true
  user_pool_id                         = aws_cognito_user_pool.kibana.id
  explicit_auth_flows                  = ["USER_PASSWORD_AUTH", "ADMIN_NO_SRP_AUTH"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_flows                  = ["code", "implicit"]
  allowed_oauth_scopes                 = ["phone", "email", "openid", "profile", "aws.cognito.signin.user.admin"]
  callback_urls                        = ["${var.elk_endpoint}/oauth2/idpresponse"]
  supported_identity_providers         = ["COGNITO"]
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
