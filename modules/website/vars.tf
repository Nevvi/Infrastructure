variable "site_name" {
  description = "The full name of the site"
}

variable "create_www_alias" {
  description = "Whether or not A record is created for www"
  default = false
}

variable "site_zone" {
  description = "The zone the site lives in"
}

variable "cloudfront_cname_aliases" {
  description = "The CNAME aliases for the cloudfront distribution"
}

variable "site_cert_name" {
  description = "The cert domain name"
}

variable "environment" {
  description = "Environment"
}