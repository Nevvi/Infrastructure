resource "aws_cognito_user_pool" "user_pool" {
  name = var.user_pool_name
  alias_attributes = ["preferred_username"]
  password_policy {
    minimum_length = 8
    require_lowercase = true
    require_uppercase = true
    require_numbers = true
    require_symbols = true
  }
}