// USER POOL

resource "aws_cognito_user_pool" "user_pool" {
  name = var.user_pool_name
  username_attributes = ["phone_number"]
  auto_verified_attributes = ["phone_number"]

  sms_configuration {
    external_id    = "f577c505-dfa3-437a-afcc-ecf532b24f70"
    sns_caller_arn = "arn:aws:iam::275527036335:role/service-role/nevvi-sms-role"
    sns_region     = "us-east-1"
  }

  account_recovery_setting {
      recovery_mechanism {
        name     = "verified_phone_number"
        priority = 1
      }

      recovery_mechanism {
        name     = "verified_email"
        priority = 2
      }
    }

  password_policy {
    minimum_length = 8
    require_lowercase = true
    require_uppercase = true
    require_numbers = true
    require_symbols = true
    temporary_password_validity_days = 7
  }
}

resource "aws_cognito_user_pool_client" "authentication_app_client" {
  name = "authentication_api"
  user_pool_id = aws_cognito_user_pool.user_pool.id
  generate_secret = false
  prevent_user_existence_errors = "LEGACY"
  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_ADMIN_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH"
  ]
}

// Outputs

resource "aws_ssm_parameter" "user_pool_id" {
  name  = "/nevvi/cognito/${var.user_pool_name}/id"
  type  = "String"
  value = aws_cognito_user_pool.user_pool.id
}

resource "aws_ssm_parameter" "user_pool_arn" {
  name  = "/nevvi/cognito/${var.user_pool_name}/arn"
  type  = "String"
  value = aws_cognito_user_pool.user_pool.arn
}

resource "aws_ssm_parameter" "user_pool_app_client" {
  name  = "/nevvi/cognito/${var.user_pool_name}/clients/authentication/id"
  type  = "String"
  value = aws_cognito_user_pool_client.authentication_app_client.id
  overwrite = true
}

// API POOL

resource "aws_cognito_user_pool" "api_pool" {
  name = var.api_pool_name
}

resource "aws_cognito_user_pool_domain" "api_pool_domain" {
  domain       = var.api_pool_name
  user_pool_id = aws_cognito_user_pool.api_pool.id
}

resource "aws_cognito_resource_server" "user_api_resource" {
  identifier = "user_api"
  name       = "user_api"

  scope {
    scope_name        = "user_api.all"
    scope_description = "All access to API"
  }

  user_pool_id = aws_cognito_user_pool.api_pool.id
}

resource "aws_cognito_user_pool_client" "authentication_api_client" {
  name = "authentication-api-client"
  user_pool_id = aws_cognito_user_pool.api_pool.id
  generate_secret = true

  allowed_oauth_scopes = ["user_api/user_api.all"]
  allowed_oauth_flows = ["client_credentials"]
  allowed_oauth_flows_user_pool_client = true
}

resource "aws_cognito_user_pool_client" "user_api_client" {
  name = "user-api-client"
  user_pool_id = aws_cognito_user_pool.api_pool.id
  generate_secret = true

  allowed_oauth_scopes = ["user_api/user_api.all"]
  allowed_oauth_flows = ["client_credentials"]
  allowed_oauth_flows_user_pool_client = true
}

// Outputs

resource "aws_ssm_parameter" "api_pool_id" {
  name  = "/nevvi/cognito/${var.api_pool_name}/id"
  type  = "String"
  value = aws_cognito_user_pool.api_pool.id
}

resource "aws_ssm_parameter" "api_pool_arn" {
  name  = "/nevvi/cognito/${var.api_pool_name}/arn"
  type  = "String"
  value = aws_cognito_user_pool.api_pool.arn
}

resource "aws_ssm_parameter" "api_pool_authentication_client_id" {
  name  = "/nevvi/cognito/${var.api_pool_name}/clients/authentication/id"
  type  = "String"
  value = aws_cognito_user_pool_client.authentication_api_client.id
  overwrite = true
}

resource "aws_ssm_parameter" "api_pool_authentication_client_secret" {
  name  = "/nevvi/cognito/${var.api_pool_name}/clients/authentication/secret"
  type  = "SecureString"
  value = aws_cognito_user_pool_client.authentication_api_client.client_secret
  overwrite = true
}

resource "aws_ssm_parameter" "api_pool_user_client_id" {
  name  = "/nevvi/cognito/${var.api_pool_name}/clients/user/id"
  type  = "String"
  value = aws_cognito_user_pool_client.user_api_client.id
  overwrite = true
}

resource "aws_ssm_parameter" "api_pool_user_client_secret" {
  name  = "/nevvi/cognito/${var.api_pool_name}/clients/user/secret"
  type  = "SecureString"
  value = aws_cognito_user_pool_client.user_api_client.client_secret
  overwrite = true
}