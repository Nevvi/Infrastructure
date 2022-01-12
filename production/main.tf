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

module "notification_table" {
  source = "../modules/database"
  table_name = "notification"
}