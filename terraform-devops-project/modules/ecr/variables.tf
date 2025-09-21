variable "repository_name" {
  description = "Name of the ECR repository"
  type        = string
  
  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-_]*[a-z0-9]$", var.repository_name))
    error_message = "Repository name must contain only lowercase letters, numbers, hyphens, and underscores."
  }
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}