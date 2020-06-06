data "aws_lambda_function" "pre_signup_trigger" {
  function_name = var.pre_signup_function_name
}

resource "aws_lambda_permission" "invoke_pre_signup" {
  statement_id  = "${var.user_pool_name}-invoke-pre-signup"
  action        = "lambda:InvokeFunction"
  function_name = var.pre_signup_function_name
  principal     = "cognito-idp.amazonaws.com"
  source_arn = aws_cognito_user_pool.user_pool.arn
}

resource "aws_cognito_user_pool" "user_pool" {
  name = var.user_pool_name
  alias_attributes = ["preferred_username"]

  password_policy {
    minimum_length = 8
    require_lowercase = true
    require_uppercase = true
    require_numbers = true
    require_symbols = true
    temporary_password_validity_days = 7
  }

  lambda_config {
    pre_sign_up = data.aws_lambda_function.pre_signup_trigger.arn
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

resource "aws_ssm_parameter" "user_pool_app_client" {
  name  = "/nevvi/cognito/${var.user_pool_name}/clients/authentication/id"
  type  = "String"
  value = aws_cognito_user_pool_client.authentication_app_client.id
}