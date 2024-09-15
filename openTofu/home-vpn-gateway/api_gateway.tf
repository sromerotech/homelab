variable "aws_api_path_root" {
 type        = string
 default     = "prod"
}

# Defines the API in the AWS Gateway service
resource "aws_api_gateway_rest_api" "home_vpn_api" {
  name        = "HomeVpnAPI"
  description = "API to interact with the Home VPN instance via Lambda"
}


# Configure the deployment of the Gateway API
resource "aws_api_gateway_deployment" "home_vpn_deployment" {
  rest_api_id = aws_api_gateway_rest_api.home_vpn_api.id
  stage_name  = var.aws_api_path_root

  triggers = {
    redeployment = sha1(join(",", [
      aws_api_gateway_method.all.id,
      aws_api_gateway_integration.lambda_integration_all.id
    ]))
  }

  depends_on = [
    aws_api_gateway_method.all,
    aws_api_gateway_integration.lambda_integration_all,
    aws_lambda_permission.api_gateway_invoke
  ]
}
