variable "location" {
  description = "Azure region"
  type        = string
  default     = "East US"
}

variable "environment" {
  description = "Deployment environment label"
  type        = string
  default     = "dev"
}

variable "sql_admin_login" {
  description = "Administrator login for the demo SQL server"
  type        = string
  default     = "sqladminuser"
}

variable "sql_admin_password" {
  description = "SQL administrator password; supply securely through TF_VAR_sql_admin_password or a protected secret store"
  type        = string
  sensitive   = true
  nullable    = false
}
