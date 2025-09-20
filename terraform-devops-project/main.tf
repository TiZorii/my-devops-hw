# main.tf
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.11"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# Kubernetes provider
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)
  
  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
  }
}

# Helm provider
provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_ca_certificate)
    
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name]
    }
  }
}

# VPC модуль
module "vpc" {
  source = "./modules/vpc"
  
  vpc_cidr = var.vpc_cidr
  project_name = var.project_name
  availability_zones = var.availability_zones
}

# ECR модуль
module "ecr" {
  source = "./modules/ecr"
  
  repository_name = var.ecr_repository_name
  project_name = var.project_name
}

# EKS модуль
module "eks" {
  source = "./modules/eks"
  
  cluster_name = var.cluster_name
  vpc_id = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids = module.vpc.public_subnet_ids
  project_name = var.project_name
}

# RDS модуль
module "rds" {
  source = "./modules/rds"
  
  project_name = var.project_name
  vpc_id = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  
  use_aurora = var.use_aurora
  engine = "postgres"
  engine_version = "15.8"
  instance_class = "db.t3.micro"
  
  database_name = "appdb"
  username = "dbadmin"
  
  multi_az = false  # Для dev/test
  deletion_protection = false  # Для dev/test
  skip_final_snapshot = true  # Для dev/test
}


# module "jenkins" {
#   source = "./modules/jenkins"
#   
#   cluster_name = module.eks.cluster_name
#   cluster_endpoint = module.eks.cluster_endpoint
#   cluster_ca_certificate = module.eks.cluster_ca_certificate
# }