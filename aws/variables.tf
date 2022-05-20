variable "aws_region" {
  type        = string
  default     = "us-east-2"
  description = "The AWS region to launch Elastic."
}

variable "elastic_password" {
  type        = string
  default     = "CloudSecurity"
  description = "The Elastic Dashboards/database password."
  validation {
    condition     = can(regex(".{6,}", var.elastic_password))
    error_message = "The password must be at least 6 characters in length."
  }
}