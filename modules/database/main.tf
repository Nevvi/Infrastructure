resource "aws_dynamodb_table" "table" {
  name           = var.table_name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "partitionKey"
  range_key      = "sortKey"

  attribute {
    name = "partitionKey"
    type = "S"
  }

  attribute {
    name = "sortKey"
    type = "S"
  }

  tags = {
    Name        = "${var.table_name}-dynamodb-table"
  }
}

// Outputs

resource "aws_ssm_parameter" "user_table_arn" {
  name  = "/nevvi/dynamodb/${var.table_name}/arn"
  type  = "String"
  value = aws_dynamodb_table.table.arn
}