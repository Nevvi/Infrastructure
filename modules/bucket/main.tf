resource "aws_s3_bucket" "bucket" {
  bucket = var.bucket_name
}

// Outputs
resource "aws_ssm_parameter" "bucket_arn" {
  name  = "/nevvi/s3/${var.bucket_name}/arn"
  type  = "String"
  value = aws_s3_bucket.bucket.arn
}