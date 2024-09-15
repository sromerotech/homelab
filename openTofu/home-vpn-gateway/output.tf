# Prints example
output "curl_example" {
  value = <<EOT
    curl -X POST https://${aws_api_gateway_rest_api.home_vpn_api.id}.execute-api.${var.aws_region}.amazonaws.com/${aws_api_gateway_deployment.home_vpn_deployment.stage_name}/${aws_api_gateway_resource.all.path_part} \
     -H "Content-Type: application/json" \
     -H "x-api-key: REPLACE_ME" \
     -d '{"action":"status"}'
  EOT
}
