resource "aws_dynamodb_table" "table" {
  name           = var.table_name
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "partitionKey"
  range_key      = "sortKey"

  global_secondary_index {
    hash_key = "gsi1pk"
    range_key = "gsi1sk"
    name = "GSI1"
    projection_type = "ALL"
  }

  global_secondary_index {
    hash_key = "gsi2pk"
    range_key = "gsi2sk"
    name = "GSI2"
    projection_type = "ALL"
  }

  attribute {
    name = "partitionKey"
    type = "S"
  }

  attribute {
    name = "sortKey"
    type = "S"
  }

  attribute {
    name = "gsi1pk"
    type = "S"
  }

  attribute {
    name = "gsi1sk"
    type = "S"
  }

  attribute {
    name = "gsi2pk"
    type = "S"
  }

  attribute {
    name = "gsi2sk"
    type = "S"
  }

  tags = {
    Name        = "${var.table_name}-dynamodb-table"
  }
}

// Outputs

resource "aws_ssm_parameter" "table_arn" {
  name  = "/nevvi/dynamodb/${var.table_name}/arn"
  type  = "String"
  value = aws_dynamodb_table.table.arn
}