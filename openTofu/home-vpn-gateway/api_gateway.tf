variable "aws_api_path_root" {
 type        = string
 default     = "prod"
}

resource "aws_api_gateway_rest_api" "lambda_api" {
  name        = "HomeVpnAPI"
  description = "API to interact with the Home VPN instance via Lambda"
}

resource "aws_api_gateway_resource" "lambda_resource" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
  parent_id   = aws_api_gateway_rest_api.lambda_api.root_resource_id
  path_part   = "ec2"
}

resource "aws_api_gateway_method" "post_method" {
  rest_api_id   = aws_api_gateway_rest_api.lambda_api.id
  resource_id   = aws_api_gateway_resource.lambda_resource.id
  http_method   = "POST"
  authorization = "NONE"

  # NOT WORKING
  # api_key_required = true
}

resource "aws_api_gateway_integration" "lambda_integration" {
  rest_api_id             = aws_api_gateway_rest_api.lambda_api.id
  resource_id             = aws_api_gateway_resource.lambda_resource.id
  http_method             = aws_api_gateway_method.post_method.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = "arn:aws:apigateway:${var.aws_region}:lambda:path/2015-03-31/functions/${aws_lambda_function.home_vpn_api.arn}/invocations"
}

resource "aws_api_gateway_deployment" "lambda_deployment" {
  rest_api_id = aws_api_gateway_rest_api.lambda_api.id
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

resource "aws_api_gateway_api_key" "home_vpn" {
  name        = "home-vpn-api-key"
  enabled     = true
}


# NOT WORKING
# resource "aws_api_gateway_usage_plan" "home_vpn_usage_plan" {
#   name        = "home-vpn-usage-plan"
#   description = "Usage plan for the home VPN API"

#   api_stages {
#     api_id = aws_api_gateway_rest_api.lambda_api.id
#     stage  = aws_api_gateway_deployment.lambda_deployment.stage_name
#   }
# }

# resource "aws_api_gateway_usage_plan_key" "home_vpn_usage_plan_key" {
#   key_id      = aws_api_gateway_api_key.home_vpn.id
#   key_type    = "API_KEY"
#   usage_plan_id = aws_api_gateway_usage_plan.home_vpn_usage_plan.id
# }
