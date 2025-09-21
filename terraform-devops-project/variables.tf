# variables.tf
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "devops-project"
}

variable "s3_bucket_name" {
  description = "Name of S3 bucket for Terraform state"
  type        = string
  default     = "tetiana-zorii-terraform-state"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b"]
}

variable "ecr_repository_name" {
  description = "Name of ECR repository"
  type        = string
  default     = "django-app"
}

variable "cluster_name" {
  description = "Name of EKS cluster"
  type        = string
  default     = "devops-eks-cluster"
}

variable "use_aurora" {
  description = "Whether to use Aurora cluster instead of RDS instance"
  type        = bool
  default     = false
}

variable "node_instance_types" {
  description = "Instance types for the EKS worker nodes"
  type        = list(string)
  default     = ["t2.micro"]
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}