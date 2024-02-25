provider "aws" {
  profile = "default"
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}

terraform {
  backend "s3" {
    bucket = "nevvi-development-terraform-remote-state"
    key    = "terraform-state"
    region = "us-east-1"
  }
}

module "website" {
  source = "../modules/website"
  site_name = "development.nevvi.net"
  site_zone = "nevvi.net."
  site_cert_name = "*.nevvi.net"
  cloudfront_cname_aliases = ["development.nevvi.net"]
  environment = var.environment
  backend_domain = "api.development.nevvi.net"
}

module "user_pool" {
  source = "../modules/authentication"
  user_pool_name = "nevvi-development-public-users"
  pre_signup_function_name = "authentication-development-preSignUpTrigger"
  api_pool_name = "nevvi-development-api-users"
}

resource "aws_cognito_user_pool" "user_pool_phone" {
  name = "nevvi-development-public-users-v2"
  username_attributes = ["phone_number"]
  auto_verified_attributes = ["phone_number"]

  sms_configuration {
    external_id    = "f577c505-dfa3-437a-afcc-ecf532b24f70"
    sns_caller_arn = "arn:aws:iam::275527036335:role/service-role/nevvi-sms-role"
    sns_region     = "us-east-1"
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

resource "aws_ssm_parameter" "user_pool_id" {
  name  = "/nevvi/cognito/nevvi-development-public-users-v2/id"
  type  = "String"
  value = aws_cognito_user_pool.user_pool.id
}

resource "aws_ssm_parameter" "user_pool_arn" {
  name  = "/nevvi/cognito/nevvi-development-public-users-v2/arn"
  type  = "String"
  value = aws_cognito_user_pool.user_pool.arn
}

resource "aws_ssm_parameter" "user_pool_app_client" {
  name  = "/nevvi/cognito/nevvi-development-public-users-v2/clients/authentication/id"
  type  = "String"
  value = aws_cognito_user_pool_client.authentication_app_client.id
  overwrite = true
}

module "user_images_bucket" {
  source = "../modules/bucket"
  bucket_name = "nevvi-user-images-dev"
}

module "notification_queue" {
  source = "../modules/queue"
  queue_name = "notifications-dev"
}