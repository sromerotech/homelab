# Defines a API Path
resource "aws_api_gateway_resource" "all" {
  rest_api_id = aws_api_gateway_rest_api.home_vpn_api.id
  parent_id   = aws_api_gateway_rest_api.home_vpn_api.root_resource_id
  path_part   = "ec2"
}

# Defines an HTTP method call in the previous API and Path
resource "aws_api_gateway_method" "all" {
  rest_api_id   = aws_api_gateway_rest_api.home_vpn_api.id
  resource_id   = aws_api_gateway_resource.all.id
  http_method   = "POST"
  authorization = "NONE"

  api_key_required = true
}

# Connects API Path and HTTP method with the Lambda function
# by making an HTTP call to the lambda when a client hits the Gateway API
resource "aws_api_gateway_integration" "lambda_integration_all" {
  rest_api_id             = aws_api_gateway_rest_api.home_vpn_api.id
  resource_id             = aws_api_gateway_resource.all.id
  http_method             = aws_api_gateway_method.all.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${aws_lambda_function.home_vpn_api.arn}/invocations"
}
