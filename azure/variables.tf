variable "az_location" {
  type        = string
  default     = "westeurope"
  description = "The Azure region to launch Elastic."
}

variable "elastic_app_password" {
  type        = string
  default     = "CloudSecurity"
  description = "The Elastic Dashboards/database password."
  validation {
    condition     = can(regex(".{6,}", var.elastic_app_password))
    error_message = "The password must be at least 6 characters in length."
  }
}

variable "elastic_vm_password" {
  type    = string
  default = "C1oud$ecurity"
  validation {
    condition     = can(regex("\\W", var.elastic_vm_password))
    error_message = "The password must have at least one special character."
  }
  validation {
    condition     = can(regex("[[:digit:]]", var.elastic_vm_password))
    error_message = "The password must have at least one number."
  }
  validation {
    condition     = can(regex("[[:upper:]]", var.elastic_vm_password))
    error_message = "The password must have at least one uppercase letter."
  }
  validation {
    condition     = can(regex("[[:lower:]]", var.elastic_vm_password))
    error_message = "The password must have at least one lowercase letter."
  }
  validation {
    condition     = can(regex(".{12,72}", var.elastic_vm_password))
    error_message = "The password must be between 12 and 72 characters in length."
  }
}

variable "victim_vm_password" {
  type    = string
  default = "C1oud$ecurity"
  validation {
    condition     = can(regex("\\W", var.victim_vm_password))
    error_message = "The password must have at least one special character."
  }
  validation {
    condition     = can(regex("[[:digit:]]", var.victim_vm_password))
    error_message = "The password must have at least one number."
  }
  validation {
    condition     = can(regex("[[:upper:]]", var.victim_vm_password))
    error_message = "The password must have at least one uppercase letter."
  }
  validation {
    condition     = can(regex("[[:lower:]]", var.victim_vm_password))
    error_message = "The password must have at least one lowercase letter."
  }
  validation {
    condition     = can(regex(".{12,72}", var.victim_vm_password))
    error_message = "The password must be between 12 and 72 characters in length."
  }
}