variable "aws_api_path_root" {
 type        = string
 default     = "prod"
}

# Defines the API in the AWS Gateway service
resource "aws_api_gateway_rest_api" "home_vpn_api" {
  name        = "HomeVpnAPI"
  description = "API to interact with the Home VPN instance via Lambda"
}

# Defines a API Path
resource "aws_api_gateway_resource" "main_path" {
  rest_api_id = aws_api_gateway_rest_api.home_vpn_api.id
  parent_id   = aws_api_gateway_rest_api.home_vpn_api.root_resource_id
  path_part   = "ec2"
}

# Defines an HTTP method call in the previous API and Path
resource "aws_api_gateway_method" "post_method" {
  rest_api_id   = aws_api_gateway_rest_api.home_vpn_api.id
  resource_id   = aws_api_gateway_resource.main_path.id
  http_method   = "POST"
  authorization = "NONE"

  api_key_required = true
}

# Connects API Path and HTTP method with the Lambda function
# by making an HTTP call to the lambda when a client hits the Gateway API
resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.home_vpn_api.id
  resource_id             = aws_api_gateway_resource.main_path.id
  http_method             = aws_api_gateway_method.post_method.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${aws_lambda_function.home_vpn_api.arn}/invocations"
}

# Configure the deployment of the Gateway API
resource "aws_api_gateway_deployment" "home_vpn_deployment" {
  rest_api_id = aws_api_gateway_rest_api.home_vpn_api.id
  stage_name  = var.aws_api_path_root

  triggers = {
    redeployment = sha1(join(",", [
      aws_api_gateway_method.post_method.id,
      aws_api_gateway_integration.lambda_integration.id
    ]))
  }

  depends_on = [
    aws_api_gateway_method.post_method,
    aws_api_gateway_integration.lambda_integration,
    aws_lambda_permission.api_gateway_invoke
  ]
}
