# Provider configuration
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.0"
}

provider "aws" {
  region = var.aws_region
  
  default_tags {
    tags = {
      Project     = "Django Kubernetes"
      Environment = var.environment
      Lesson      = "7"
    }
  }
}

# Local values
locals {
  project_name = "django-k8s"
  common_tags = {
    Project     = "Django Kubernetes"
    Environment = var.environment
    Lesson      = "7"
  }
}

# Data sources 
data "aws_vpc" "existing" {
  id = "vpc-0014c3afc3d0cc232"
}

data "aws_subnets" "private" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.existing.id]
  }
  
  filter {
    name   = "state"
    values = ["available"]
  }
}

# ECR Module
module "ecr" {
  source = "./modules/ecr"
  
  repository_name = "${local.project_name}-app"
  tags            = local.common_tags
}

# EKS Module
module "eks" {
  source = "./modules/eks"
  
  cluster_name         = "${local.project_name}-cluster"
  kubernetes_version   = var.kubernetes_version
  subnet_ids           = data.aws_subnets.private.ids
  public_access_cidrs  = var.public_access_cidrs
  
  # Node group configuration
  capacity_type   = "ON_DEMAND"
  instance_types  = ["t3.micro"]
  desired_size    = 2
  min_size        = 1
  max_size        = 6
  
  tags = local.common_tags
}