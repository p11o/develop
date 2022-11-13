
data "aws_iam_policy" "lambda" {
  name = "AWSLambdaRole"
}

data "aws_iam_policy" "gateway_cloudwatch" {
  name = "AmazonAPIGatewayPushToCloudWatchLogs"
}
