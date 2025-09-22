# ===========================================
# DevOps Final Project - Main Configuration
# ===========================================

# Локальні змінні
locals {
  name_prefix = "${var.project_name}-${var.environment}"
  
  # AWS дані з providers.tf
  account_id = data.aws_caller_identity.current.account_id
  region     = data.aws_region.current.name
  azs        = length(var.availability_zones) > 0 ? var.availability_zones : slice(data.aws_availability_zones.available.names, 0, 2)
  
  # Об'єднуємо теги з додатковою інформацією
  common_tags = merge(var.common_tags, {
    Name      = local.name_prefix
    Region    = local.region
    AccountId = local.account_id
    CreatedBy = "terraform"
    CreatedAt = timestamp()
  })
  
  # CIDR блоки для підмереж
  public_subnets   = [for i in range(length(local.azs)) : cidrsubnet(var.vpc_cidr, 8, i)]
  private_subnets  = [for i in range(length(local.azs)) : cidrsubnet(var.vpc_cidr, 8, i + 10)]
  database_subnets = [for i in range(length(local.azs)) : cidrsubnet(var.vpc_cidr, 8, i + 20)]
}

# ===========================================
# Data Sources
# ===========================================

# EKS cluster authentication
data "aws_eks_cluster_auth" "cluster" {
  name = module.eks.cluster_name
}

# ===========================================
# VPC модуль
# ===========================================

module "vpc" {
  source = "./modules/vpc"
  
  project_name       = var.project_name
  environment        = var.environment
  vpc_cidr          = var.vpc_cidr
  availability_zones = local.azs
  
  # Free Tier оптимізації
  enable_nat_gateway     = true   # Потрібно для EKS
  single_nat_gateway     = true   # Економія: $45/міс замість $90/міс
  enable_flow_logs       = false  # Відключено для економії
  enable_vpn_gateway     = false  # Не потрібно для dev
  
  # Security groups
  create_database_security_group = true
  create_eks_security_group      = true
  
  tags = local.common_tags
}

# ===========================================
# ECR модуль
# ===========================================

module "ecr" {
  source = "./modules/ecr"
  
  project_name = var.project_name
  environment  = var.environment
  
  # ECR налаштування
  image_tag_mutability         = "MUTABLE"  # Для dev середовища
  encryption_type             = "AES256"    # Free encryption
  enable_vulnerability_scanning = true      # Безпека
  
  # Lifecycle policy для економії місця
  max_image_count      = 10  # Максимум 10 образів
  untagged_image_days  = 7   # Видаляти untagged через тиждень
  
  tags = local.common_tags
}

# ===========================================
# EKS модуль
# ===========================================

module "eks" {
  source = "./modules/eks"
  
  project_name          = var.project_name
  environment           = var.environment
  vpc_id               = module.vpc.vpc_id
  private_subnet_ids   = module.vpc.private_subnet_ids
  
  # Security groups з VPC модуля
  cluster_security_group_ids = [module.vpc.eks_cluster_security_group_id]
  node_security_group_ids   = [module.vpc.eks_nodes_security_group_id]
  
  kubernetes_version    = var.kubernetes_version
  node_instance_types   = var.node_instance_types
  node_desired_capacity = var.node_desired_capacity
  node_max_capacity     = var.node_max_capacity
  node_min_capacity     = var.node_min_capacity
  
  # Free Tier оптимізації
  node_capacity_type   = "ON_DEMAND"  # Можна змінити на SPOT для економії
  node_disk_size      = 20           # Мінімальний розмір
  endpoint_public_access = true       # Для доступу ззовні
  
  tags = local.common_tags
}

# ===========================================
# RDS модуль
# ===========================================

module "rds" {
  source = "./modules/rds"
  
  project_name         = var.project_name
  environment          = var.environment
  vpc_id               = module.vpc.vpc_id
  db_subnet_group_name = module.vpc.database_subnet_group_name

  # Security - дозволяємо доступ тільки з EKS nodes
  allowed_security_group_ids = [module.vpc.eks_nodes_security_group_id]
  allowed_cidr_blocks       = module.vpc.private_subnet_cidr_blocks

  db_instance_class    = var.db_instance_class
  db_allocated_storage = var.db_allocated_storage
  db_engine_version    = var.db_engine_version
  db_name              = var.db_name
  db_username          = var.db_username
  db_password          = var.db_password

  # Free Tier оптимізації
  db_storage_type                     = "gp3"  # Найдешевший тип
  db_storage_encrypted                = true   # Безпека
  auto_minor_version_upgrade          = true
  store_credentials_in_secrets_manager = true

  tags = local.common_tags
}

# ===========================================
# Jenkins CI/CD Module
# ===========================================

module "jenkins" {
  source = "./modules/jenkins"
  
  jenkins_namespace      = "jenkins"
  jenkins_admin_password = var.jenkins_admin_password
  
  # EKS cluster information
  eks_cluster_name                       = module.eks.cluster_name
  eks_cluster_endpoint                   = module.eks.cluster_endpoint
  eks_cluster_certificate_authority_data = module.eks.cluster_certificate_authority_data
  eks_cluster_token                      = data.aws_eks_cluster_auth.cluster.token
  
  # ECR repository for Docker images
  ecr_repository_url = module.ecr.django_app_repository_url
  
  region = var.region
}

# ===========================================
# ArgoCD GitOps Module
# ===========================================

module "argocd" {
  source = "./modules/argo_cd"
  
  namespace     = "argocd"
  chart_version = "5.51.6"
}

# ===========================================
# Providers for Kubernetes and Helm
# ===========================================

# Kubernetes provider configuration
provider "kubernetes" {
  host                   = module.eks.cluster_endpoint
  cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
  token                  = data.aws_eks_cluster_auth.cluster.token

  exec {
    api_version = "client.authentication.k8s.io/v1beta1"
    command     = "aws"
    args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", var.region]
  }
}

# Helm provider configuration
provider "helm" {
  kubernetes {
    host                   = module.eks.cluster_endpoint
    cluster_ca_certificate = base64decode(module.eks.cluster_certificate_authority_data)
    token                  = data.aws_eks_cluster_auth.cluster.token

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "aws"
      args = ["eks", "get-token", "--cluster-name", module.eks.cluster_name, "--region", var.region]
    }
  }
}