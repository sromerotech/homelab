output "curl_example" {
  value = <<EOT
    curl -X POST https://${aws_api_gateway_rest_api.lambda_api.id}.execute-api.${var.aws_region}.amazonaws.com/${aws_api_gateway_deployment.lambda_deployment.stage_name}/${aws_api_gateway_resource.lambda_resource.path_part} \
     -H "Content-Type: application/json" \
     -d '{"action":"status"}'
  EOT
}
