# Defines a permanent Gateway API
resource "aws_api_gateway_api_key" "home_vpn" {
  name        = "home-vpn-api-key"
  enabled     = true
}

# Defines an API usage plan for our API
resource "aws_api_gateway_usage_plan" "home_vpn_usage_plan" {
  name        = "home-vpn-usage-plan"
  description = "Usage plan for the home VPN API"

  api_stages {
    api_id = aws_api_gateway_rest_api.home_vpn_api.id
    stage  = aws_api_gateway_deployment.home_vpn_deployment.stage_name
  }

  throttle_settings {
    burst_limit = 1
    rate_limit = 1
  }
}

# Associates our API key to the usage plan
resource "aws_api_gateway_usage_plan_key" "home_vpn_usage_plan_key" {
  key_id      = aws_api_gateway_api_key.home_vpn.id
  key_type    = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.home_vpn_usage_plan.id
}
