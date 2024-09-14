# Defines the lambda function from the source code
resource "aws_lambda_function" "home_vpn_api" {
  function_name    = "homeVPNApi"
  role             = aws_iam_role.lambda_execution_role.arn
  handler          = "function.lambda_handler"
  runtime          = "python3.9"
  filename         = "${path.module}/lambda_function.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda_function.zip")

  environment {
    variables = {
      INSTANCE_ID = var.aws_instance_id
    }
  }

  # NOTT WORKING
  # depends_on = [null_resource.zip_lambda_function]
}

# Grants execution permissions to AWS Gateway
resource "aws_lambda_permission" "api_gateway_invoke" {
  statement_id  = "AllowExecutionFromApiGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.home_vpn_api.function_name
  principal     = "apigateway.amazonaws.com"
}

// NOT WORKING
// Ensure the zip file is created before Lambda function is created
// resource "null_resource" "zip_lambda_function" {
//   provisioner "local-exec" {
//     command = "cd lambda && zip -r ../lambda_function.zip function.py"
//   }

//   triggers = {
//     lambda_file_hash = filemd5("lambda/function.py")
//   }
// }
