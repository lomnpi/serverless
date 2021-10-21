terraform {
  required_providers {
      aws = {
          source = "hashicorp/aws"
          version = "~> 3.0"
      }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
    description = "The AWS Region to deploy to (e.g. us-east-1). **Regex enforced**"
    type = string

    validation {
        condition = can(regex("(us(-gov)?|ap|ca|cn|eu|sa)-(central|(north|south)?(east|west)?)-\\d", var.aws_region))
        error_message = "The aws_region value must be a valid AWS Region."
    }
}

variable "hash_function_name" {
    description = "The name of the Lambda function to create."
    type = string
}

variable "s3_bucket_name" {
    description = "The name of the S3 Bucket to create."
    type = string
}

# Role for lambda function
resource "aws_iam_role" "lambda_function_role" {
    name = "lambda_function_role"

    assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = "sts:AssumeRole"
                Effect = "Allow"
                Sid = ""
                Principal = {
                    Service = "lambda.amazonaws.com"
                }
            }
        ]
    })
}

# Managed IAM Policy for Hash Function
# Reusable and avoid cycle dependency
resource "aws_iam_policy" "hash_function_iam_policy" {
    name = "lambda_s3_policy"
    path = "/"
    description = "IAM policy to access S3 bucket objects"

    policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
            {
                Action = [
                    "logs:CreateLogGroup",
                    "logs:CreateLogStream",
                    "logs:PutLogEvents"
                ]
                Effect = "Allow"
                Resource = "*"
            },
            {
                Action = [
                    "s3:GetObject",
                    "s3:PutObject"
                ]
                Effect = "Allow"
                Resource = "${aws_s3_bucket.processing_s3_bucket.arn}/*"
            }
        ]
    })
}

# Attaching IAM Policy to IAM Role
resource "aws_iam_role_policy_attachment" "s3_access" {
    role = aws_iam_role.lambda_function_role.name
    policy_arn = aws_iam_policy.hash_function_iam_policy.arn
}

# Lambda function for hashing '.csv' and '.json'
resource "aws_lambda_function" "hash_function" {
    function_name = var.hash_function_name
    role = aws_iam_role.lambda_function_role.arn
    runtime = "python3.8"
    timeout = 5
    memory_size = 128
    handler = "hash.handler"
    filename = "./src/hash_lambda_function.zip"
    source_code_hash = filebase64sha256("./src/hash_lambda_function.zip")
    
    # tracing_config {
    #     mode = "Active"
    # }
    
}

# KMS key for S3 bucket server-side encryption
# Grants Lambda function permission decrypt objects in S3 bucket
resource "aws_kms_key" "kms_key" {
    policy = jsonencode({
        Version = "2012-10-17"
        Id = "key-s3"
        Statement = [
            {
                Sid = "Enable IAM User Permissions"
                Effect = "Allow"
                Principal = {
                    AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
                }
                Action = "kms:*"
                Resource = "*"
            },
            {
                Sid = "Allow VPC Flow Logs to use the key as well"
                Effect = "Allow"
                Principal = {
                    Service = "delivery.logs.amazonaws.com"
                }
                Action = "kms:GenerateDataKey*"
                Resource = "*"
            },
            {
                Sid = "Allow function to decrypt obbjects"
                Effect = "Allow"
                Principal = {
                    AWS = "${aws_iam_role.lambda_function_role.arn}"
                }
                Action = [
                    "kms:Decrypt",
                    "kms:GenerateDataKey"
                ]
                Resource = "*"
            }
        ]
    })
}

# Alias for KMS key
resource "aws_kms_alias" "kms_key_alias" {
    name = "alias/${var.s3_bucket_name}-key"
    target_key_id = aws_kms_key.kms_key.key_id
}

# S3 bucket for eligible members - stores processing files (.csv and .json)
resource "aws_s3_bucket" "processing_s3_bucket" {
    bucket_prefix = "${var.s3_bucket_name}"

    server_side_encryption_configuration {
        rule {
            apply_server_side_encryption_by_default {
                kms_master_key_id = aws_kms_alias.kms_key_alias.arn
                sse_algorithm = "aws:kms"
            }
        }
    }

    versioning {
        enabled = true
    }

    lifecycle {
      prevent_destroy = true
    }
}

# Lambda invoke permission for S3 bucket
resource "aws_lambda_permission" "s3_bucket_invoke" {
    statement_id  = "AllowExecutionFromS3Bucket"
    action        = "lambda:InvokeFunction"
    function_name = aws_lambda_function.hash_function.arn
    principal     = "s3.amazonaws.com"
    source_arn    = aws_s3_bucket.processing_s3_bucket.arn
}

# S3 bucket events configuration to invoke hash function
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.processing_s3_bucket.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.hash_function.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".csv"
  }

  lambda_function {
    lambda_function_arn = aws_lambda_function.hash_function.arn
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".json"
  }

  depends_on = [
    aws_lambda_permission.s3_bucket_invoke
  ]
}

data "aws_caller_identity" "current" {}