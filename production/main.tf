provider "aws" {
  profile = "default"
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}

terraform {
  backend "s3" {
    bucket = "nevvi-production-terraform-remote-state"
    key    = "terraform-state"
    region = "us-east-1"
  }
}

module "website" {
  source = "../modules/website"
  site_name = "nevvi.net"
  create_www_alias = true
  site_zone = "nevvi.net."
  site_cert_name = "www.nevvi.net"
  cloudfront_cname_aliases = ["nevvi.net", "www.nevvi.net"]
  environment = var.environment
  backend_domain = "api.nevvi.net"
}

module "user_pool" {
  source = "../modules/authentication"
  user_pool_name = "nevvi-public-users"
  api_pool_name = "nevvi-api-users"
  pre_signup_function_name = "authentication-production-preSignUpTrigger"
}

module "user_images_bucket" {
  source = "../modules/bucket"
  bucket_name = "nevvi-user-images"
}

module "notification_queue" {
  source = "../modules/queue"
  queue_name = "notifications"
}

module "refresh_suggestions_queue" {
  source = "../modules/queue"
  queue_name = "refresh-suggestions"
}

resource "random_uuid" "authentication_api_key" {
}

resource "aws_ssm_parameter" "authentication_api_key_param" {
  name        = "/nevvi/lambda/production/authentication-api-key"
  description = "Api key string for M2M communication to authentication service"
  type        = "SecureString"
  value       = random_uuid.authentication_api_key.result
}

resource "random_uuid" "user_api_key" {
}

resource "aws_ssm_parameter" "user_api_key_param" {
  name        = "/nevvi/lambda/production/user-api-key"
  description = "Api key string for M2M communication to user service"
  type        = "SecureString"
  value       = random_uuid.user_api_key.result
}