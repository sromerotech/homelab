# Defines a role that the AWS Lambda service can assume
resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda_ec2_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
    }]
  })
}

# Defines an IAM policy for the previous role to interact with EC2
resource "aws_iam_policy" "lambda_ec2_policy" {
  name = "lambda_ec2_policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "ec2:StartInstances",
        "ec2:StopInstances",
        "ec2:DescribeInstances"
      ]
      Effect   = "Allow"
      Resource = "*"
    }]
  })
}

# Connects role with the policy
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_ec2_policy.arn
}
