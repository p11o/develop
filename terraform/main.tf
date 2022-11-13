# variable "name" {
#   default = "success"
# }
# variable "region" {
#   type    = string
#   default = "us-east-1"
# }

# terraform {
#   required_providers {
#     aws = {
#       source  = "hashicorp/aws"
#       version = "~> 4.0"
#     }
#   }
# }

# provider "aws" {
#   region = var.region
# }

# resource "aws_s3_bucket" "code" {
#   bucket = "presto-code"
# }

# resource "aws_s3_object" "package" {
#   bucket = aws_s3_bucket.code.bucket
#   key    = "code/${var.name}/${filemd5(data.archive_file.lambda.output_path)}.zip"
#   source = data.archive_file.lambda.output_path

#   etag = filemd5(data.archive_file.lambda.output_path)
# }

# data "archive_file" "lambda" {
#   type        = "zip"
#   source_dir  = "../src/${var.name}"
#   output_path = "../dist/${var.name}.zip"
# }

# data "aws_iam_policy" "lambda" {
#   name = "AWSLambdaRole"
# }

# data "aws_iam_policy" "gateway_cloudwatch" {
#   name = "AmazonAPIGatewayPushToCloudWatchLogs"
# }

# resource "aws_iam_role" "test_app" {
#   name = "test_app_role"

#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = ["sts:AssumeRole"]
#         Effect = "Allow"
#         Principal = {
#           Service = "lambda.amazonaws.com"
#         }
#       },
#       {
#         Action = ["sts:AssumeRole"]
#         Effect = "Allow"
#         Principal = {
#           Service = "apigateway.amazonaws.com"
#         }
#       },
#     ]
#   })
#   managed_policy_arns = [
#     data.aws_iam_policy.lambda.arn,
#   ]
# }

# resource "aws_lambda_function" "success" {
#   s3_bucket = aws_s3_bucket.code.bucket
#   s3_key    = aws_s3_object.package.key

#   function_name = "test_${var.name}"

#   # Shortcut to more strict roles
#   role    = aws_iam_role.test_app.arn
#   handler = "main.handler"
#   runtime = "python3.9"
# }

# resource "aws_api_gateway_rest_api" "app" {
#   name = "test_app"
# }

# resource "aws_api_gateway_resource" "success" {
#   rest_api_id = aws_api_gateway_rest_api.app.id
#   parent_id   = aws_api_gateway_rest_api.app.root_resource_id
#   path_part   = "success"
# }

# resource "aws_api_gateway_method" "success" {
#   rest_api_id   = aws_api_gateway_rest_api.app.id
#   resource_id   = aws_api_gateway_resource.success.id
#   http_method   = "GET"
#   authorization = "NONE"
# }

# resource "aws_api_gateway_integration" "integration" {
#   rest_api_id             = aws_api_gateway_rest_api.app.id
#   resource_id             = aws_api_gateway_resource.success.id
#   http_method             = aws_api_gateway_method.success.http_method
#   credentials             = aws_iam_role.test_app.arn
#   integration_http_method = "POST"
#   type                    = "AWS_PROXY"
#   uri                     = "arn:aws:apigateway:${var.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.success.arn}/invocations"
# }

# resource "aws_lambda_permission" "apigw_lambda" {
#   statement_id  = "AllowExecutionFromAPIGateway"
#   action        = "lambda:InvokeFunction"
#   function_name = aws_lambda_function.success.arn
#   principal     = "apigateway.amazonaws.com"

#   # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
#   source_arn = "arn:aws:execute-api:${var.region}::${aws_api_gateway_rest_api.app.id}/*/${aws_api_gateway_method.success.http_method}${aws_api_gateway_resource.success.path}"
# }

# resource "aws_api_gateway_deployment" "dev" {
#   depends_on  = [aws_api_gateway_integration.integration]
#   rest_api_id = aws_api_gateway_rest_api.app.id
#   stage_name  = "dev"
# }

# resource "aws_iam_role" "cloudwatch" {
#   name = "APIGatewayCloudwatch"
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17"
#     Statement = [
#       {
#         Action = ["sts:AssumeRole"]
#         Effect = "Allow"
#         Principal = {
#           Service = "apigateway.amazonaws.com"
#         }
#       },
#     ]
#   })
#   managed_policy_arns = [
#     data.aws_iam_policy.gateway_cloudwatch.arn
#   ]
# }

# resource "aws_api_gateway_account" "account" {
#   cloudwatch_role_arn = aws_iam_role.cloudwatch.arn
# }
