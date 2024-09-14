# OpenTofu Home VPN Gateway

This project provisions an AWS Lambda function and API Gateway using OpenTofu (Terraform alternative) to start, stop, and check the status of an EC2 instance for a home VPN gateway setup. It includes API security with API keys for restricted access.

## Features
- **AWS Lambda**: Handles starting, stopping, and checking the status of the EC2 instance.
- **AWS API Gateway**: Provides a REST API interface to interact with the Lambda.
- **API Security**: Secured with API keys to restrict access.
- **IAM Roles & Policies**: Includes necessary permissions for EC2 actions (start, stop, describe).

## Prerequisites
- Docker
- A valid AWS account

## Usage
1. **Clone the repository**:
   ```bash
   git clone <repo-url>
   cd openTofu/home-vpn-gateway
   ```

2. **Set up environment variables**:
   Configure your AWS region and instance ID in a `.env` file:
   ```
   AWS_ACCESS_KEY_ID=<replace_me>
   AWS_SECRET_ACCESS_KEY=<replace_me>
   ```

3. **Deploy the infrastructure**:
   ```bash
   make init
   make apply
   ```

5. **Accessing the API**:
   Use the provided API Gateway URL and include the API key to start/stop the VPN instance.

## Security
- **API Key**: The API is secured using an API key, which must be included in all requests.
- **IAM Roles**: Limited EC2 permissions are attached to the Lambda function.
