variable "aws_instance_id" {
 description = "aws id of the Home VPN instance"
 type        = string
}

variable "aws_region" {
 description = "aws region where the code is deployed"
 type        = string
 default     = "eu-south-2"
}
