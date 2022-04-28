variable "aws_region" {
  type        = string
  default     = "us-east-2"
  description = "The AWS region to launch OpenSearch."
}

variable "opensearch_password" {
  type = string
  default = "admin"
  description = "The OpenSearch Dashboards/database password"
}