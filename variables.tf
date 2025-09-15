variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "vpc_name" {
  description = "Name of existing VPC"
  type        = string
  default     = "vpc-0014c3afc3d0cc232" 
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

variable "public_access_cidrs" {
  description = "CIDR blocks for public access to EKS"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}
