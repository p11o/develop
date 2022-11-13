
##################################
# Deploy image
variable "oauth_version" {
  type    = string
  default = "test17"
}

resource "aws_ecr_repository" "oauth" {
  name = "oauth"
}

resource "docker_registry_image" "oauth" {
  # TODO figure out tagging
  name = "${aws_ecr_repository.oauth.repository_url}:${var.oauth_version}"

  build {
    context = "${path.cwd}/../src/oauth"
  }
}


##################################
# Config lambdas
locals {
  oauth_endpoints = toset(["callback", "signin"])
  cognito_domain  = "https://${aws_cognito_user_pool_domain.main.domain}.auth.${local.region}.amazoncognito.com"
  app_url         = "https://f3whn22htb.execute-api.us-east-1.amazonaws.com/dev"
}

data "aws_iam_policy_document" "lambda_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com", "apigateway.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "oauth_app" {
  name = "oauth_app_role"

  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
  managed_policy_arns = [
    data.aws_iam_policy.lambda.arn,
  ]
}


resource "aws_lambda_function" "oauth" {
  for_each = local.oauth_endpoints

  role          = aws_iam_role.oauth_app.arn
  function_name = "oauth_${each.key}"

  package_type = "Image"
  image_uri    = docker_registry_image.oauth.name
  image_config {
    command = ["${each.key}.handler"]
  }

  environment {
    variables = {
      OAUTH_CLIENT_ID              = aws_cognito_user_pool_client.main.id
      OAUTH_CLIENT_SECRET          = aws_cognito_user_pool_client.main.client_secret
      OAUTH_TOKEN_URL              = "${local.cognito_domain}/oauth2/token"
      OAUTH_REDIRECT_URI           = "${local.app_url}/callback"
      OAUTH_AUTHORIZATION_BASE_URL = "${local.cognito_domain}/oauth2/authorize"
      OAUTH_HOME_URL               = "https://example.com"
    }
  }
}


resource "aws_api_gateway_rest_api" "oauth_app" {
  name = "oauth_app"
}

resource "aws_api_gateway_resource" "oauth" {
  for_each = local.oauth_endpoints

  rest_api_id = aws_api_gateway_rest_api.oauth_app.id
  parent_id   = aws_api_gateway_rest_api.oauth_app.root_resource_id
  path_part   = each.key
}

resource "aws_api_gateway_method" "oauth" {
  for_each = local.oauth_endpoints

  rest_api_id   = aws_api_gateway_rest_api.oauth_app.id
  resource_id   = aws_api_gateway_resource.oauth[each.key].id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "integration" {
  for_each = local.oauth_endpoints

  rest_api_id             = aws_api_gateway_rest_api.oauth_app.id
  resource_id             = aws_api_gateway_resource.oauth[each.key].id
  http_method             = aws_api_gateway_method.oauth[each.key].http_method
  credentials             = aws_iam_role.oauth_app.arn
  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = "arn:aws:apigateway:${local.region}:lambda:path/2015-03-31/functions/${aws_lambda_function.oauth[each.key].arn}/invocations"
}

resource "aws_lambda_permission" "apigw_lambda" {
  for_each = local.oauth_endpoints

  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.oauth[each.key].arn
  principal     = "apigateway.amazonaws.com"

  # More: http://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-control-access-using-iam-policies-to-invoke-api.html
  source_arn = "arn:aws:execute-api:${local.region}::${aws_api_gateway_rest_api.oauth_app.id}/*/${aws_api_gateway_method.oauth[each.key].http_method}${aws_api_gateway_resource.oauth[each.key].path}"
}

resource "aws_api_gateway_deployment" "dev" {
  for_each = local.oauth_endpoints

  depends_on  = [aws_api_gateway_integration.integration]
  rest_api_id = aws_api_gateway_rest_api.oauth_app.id
  stage_name  = "dev"
}

data "aws_iam_policy_document" "api_gateway_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "cloudwatch" {
  name               = "APIGatewayCloudwatch"
  assume_role_policy = data.aws_iam_policy_document.api_gateway_assume.json
  managed_policy_arns = [
    data.aws_iam_policy.gateway_cloudwatch.arn
  ]
}

resource "aws_api_gateway_account" "account" {
  cloudwatch_role_arn = aws_iam_role.cloudwatch.arn
}
