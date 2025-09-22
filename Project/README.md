# DevOps Final Project - AWS Infrastructure with CI/CD Pipeline

## Архітектура системи

### Компоненти інфраструктури

**AWS Services:**
- **VPC** - Virtual Private Cloud з приватними та публічними підмережами
- **EKS** - Kubernetes кластер для контейнерних додатків
- **RDS** - PostgreSQL база даних
- **ECR** - Docker Container Registry
- **S3 + DynamoDB** - Terraform state backend

**DevOps Tools:**
- **Jenkins** - CI/CD automation server
- **ArgoCD** - GitOps deployment tool
- **Helm** - Kubernetes package manager
- **Terraform** - Infrastructure as Code

**Application:**
- **Django** - Python web application
- **Docker** - Containerization
- **Kubernetes** - Container orchestration

### Схема архітектури

```
┌─────────────────────────────────────────────────────────────┐
│                        AWS VPC                              │
│                                                             │
│  ┌─────────────────┐    ┌─────────────────┐                │
│  │  Public Subnet  │    │  Public Subnet  │                │
│  │    (NAT GW)     │    │   (Internet)    │                │
│  └─────────────────┘    └─────────────────┘                │
│                                                             │
│  ┌─────────────────┐    ┌─────────────────┐                │
│  │ Private Subnet  │    │ Private Subnet  │                │
│  │  (EKS Nodes)    │    │  (EKS Nodes)    │                │
│  │                 │    │                 │                │
│  │ ┌─────────────┐ │    │ ┌─────────────┐ │                │
│  │ │   Jenkins   │ │    │ │ Django App  │ │                │
│  │ │   ArgoCD    │ │    │ │             │ │                │
│  │ └─────────────┘ │    │ └─────────────┘ │                │
│  └─────────────────┘    └─────────────────┘                │
│                                                             │
│  ┌─────────────────┐    ┌─────────────────┐                │
│  │ Database Subnet │    │ Database Subnet │                │
│  │  (RDS/Aurora)   │    │  (RDS/Aurora)   │                │
│  └─────────────────┘    └─────────────────┘                │
└─────────────────────────────────────────────────────────────┘
```

## Структура проекту

```
Project/
├── main.tf                 # Головний конфігураційний файл
├── variables.tf            # Змінні проекту
├── terraform.tf           # Terraform та провайдери
├── outputs.tf             # Outputs інфраструктури
│
├── modules/               # Terraform модулі
│  ├── vpc/               # VPC та networking
│  ├── eks/               # Kubernetes кластер
│  ├── rds/               # База даних
│  ├── ecr/               # Container registry
│  ├── jenkins/           # CI/CD сервер
│  └── argo_cd/           # GitOps deployment
│
├── charts/               # Helm charts
│  └── django-app/        # Django application chart
│     ├── templates/
│     ├── values.yaml
│     └── Chart.yaml
│
└── Django/               # Django application
   ├── app/               # Django project
   ├── api/               # API endpoints
   ├── Dockerfile         # Container image
   ├── Jenkinsfile        # CI/CD pipeline
   └── requirements.txt   # Python dependencies
```

## Встановлення та розгортання

### Передумови

**Required Software:**
- AWS CLI v2+
- Terraform v1.0+
- kubectl v1.24+
- Docker v20+
- Helm v3.8+

**AWS Credentials:**
```bash
aws configure
```

### Крок 1: Ініціалізація Terraform

```bash
# Clone repository


# Initialize Terraform
terraform init

# Review planned changes
terraform plan

# Deploy infrastructure
terraform apply
```

### Крок 2: Налаштування kubectl

```bash
# Configure kubectl
aws eks update-kubeconfig --region us-east-1 --name <cluster-name>

# Verify connection
kubectl get nodes
```

### Крок 3: Доступ до сервісів

**Jenkins:**
```bash
kubectl port-forward svc/jenkins 8080:8080 -n jenkins
# URL: http://localhost:8080
# Username: admin
# Password: DevOps2024!@#
```

**ArgoCD:**
```bash
kubectl port-forward svc/argocd-server 8081:443 -n argocd
# URL: https://localhost:8081
# Username: admin
# Password: [from terraform output]
```

### Крок 4: Деплой Django додатку

```bash
# Create application secrets
kubectl create secret generic django-db-secret \
  --from-literal=password="<db-password>"

# Deploy using Helm
helm install django-app charts/django-app/

# Verify deployment
kubectl get pods -l app=django-app
```

## CI/CD Pipeline

### Jenkins Pipeline Flow

1. **Source** - Git webhook triggers build
2. **Build** - Docker image creation
3. **Test** - Run unit tests
4. **Push** - Upload to ECR
5. **Deploy** - Update Kubernetes via ArgoCD

### ArgoCD GitOps Flow

1. **Monitor** - Watch Git repository
2. **Sync** - Detect changes in charts/
3. **Deploy** - Apply Kubernetes manifests
4. **Health** - Monitor application health

## Моніторинг та управління

### Перевірка статусу

```bash
# Infrastructure
terraform show

# Kubernetes clusters
kubectl get all -A

# Application health
kubectl get pods -l app=django-app
kubectl logs -f deployment/django-app
```

### Масштабування

```bash
# Manual scaling
kubectl scale deployment django-app --replicas=3

# Auto-scaling (HPA configured)
kubectl get hpa django-app
```

### Логи та дебагінг

```bash
# Jenkins logs
kubectl logs -f deployment/jenkins -n jenkins

# ArgoCD logs  
kubectl logs -f deployment/argocd-server -n argocd

# Application logs
kubectl logs -f deployment/django-app
```

## Безпека

### Network Security
- VPC з приватними підмережами
- Security Groups з мінімальними дозволами
- NAT Gateway для outbound traffic

### Application Security
- Secrets management через Kubernetes secrets
- IAM roles з least privilege принципом
- Container image scanning в ECR

### Access Control
- EKS RBAC налаштування
- Jenkins role-based security
- ArgoCD RBAC policies

## Troubleshooting

### Поширені проблеми

**Terraform помилки:**
```bash
# Clean and reinitialize
rm -rf .terraform
terraform init
```

**Kubernetes connectivity:**
```bash
# Update kubeconfig
aws eks update-kubeconfig --region us-east-1 --name <cluster-name>

# Check cluster status
kubectl cluster-info
```

**Pod не запускається:**
```bash
# Describe pod issues
kubectl describe pod <pod-name>

# Check resource limits
kubectl top nodes
kubectl top pods
```

**Jenkins недоступний:**
```bash
# Check service status
kubectl get svc jenkins -n jenkins

# Restart if needed
kubectl rollout restart deployment/jenkins -n jenkins
```

## Очищення ресурсів

```bash
# Delete Kubernetes resources
helm uninstall django-app
kubectl delete namespace jenkins
kubectl delete namespace argocd

# Destroy infrastructure
terraform destroy

# Verify cleanup
aws ec2 describe-instances --region us-east-1
aws rds describe-db-instances --region us-east-1
```

## Вартість оптимізації

### Free Tier компоненти
- t3.micro EC2 instances (EKS nodes)
- db.t3.micro RDS instance
- Single NAT Gateway
- gp3 storage types

### Моніторинг витрат
```bash
# Check current costs
aws ce get-cost-and-usage --time-period Start=2024-01-01,End=2024-01-31 --granularity MONTHLY --metrics BlendedCost
```
