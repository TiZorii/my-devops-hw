# DevOps CI/CD Project - Jenkins + ArgoCD + EKS

Цей проект демонструє повний CI/CD pipeline з використанням Jenkins, ArgoCD, Terraform та Amazon EKS.

## Архітектура

```
┌─────────────────┐    ┌──────────────┐    ┌─────────────────┐
│   Developer     │    │   Jenkins    │    │   Amazon ECR    │
│   (Git Push)    │───▶│   Pipeline   │───▶│   (Docker       │
└─────────────────┘    └──────────────┘    │   Registry)     │
                              │             └─────────────────┘
                              ▼
┌─────────────────┐    ┌──────────────┐    ┌─────────────────┐
│   Git Repository│◄───│   Update     │    │   ArgoCD        │
│   (Helm Charts) │    │   values.yaml│◄───│   (GitOps)      │
└─────────────────┘    └──────────────┘    └─────────────────┘
                                                    │
                                                    ▼
                                            ┌─────────────────┐
                                            │   EKS Cluster   │
                                            │   (Application) │
                                            └─────────────────┘
```

## Компоненти

- **VPC**: Приватна мережа з публічними/приватними підмережами
- **EKS Cluster**: Kubernetes кластер для запуску застосунків
- **ECR**: Docker registry для зберігання образів
- **Jenkins**: CI сервер для збирання та деплою
- **ArgoCD**: GitOps інструмент для автоматичної синхронізації
- **RDS**: PostgreSQL база даних для застосунків

## Структура проекту

```
terraform-devops-project/
├── main.tf                   # Головний конфігураційний файл
├── variables.tf              # Змінні проекту
├── outputs.tf                # Виходи Terraform
├── terraform.tfvars          # Значення змінних
├── backend.tf                # Налаштування S3 backend
│
├── modules/                  # Terraform модулі
│   ├── vpc/                  # VPC інфраструктура
│   ├── ecr/                  # Docker registry
│   ├── eks/                  # Kubernetes кластер
│   ├── jenkins/              # Jenkins CI сервер
│   ├── argo_cd/              # ArgoCD GitOps
│   └── rds/                  # База даних
│
└── charts/                   # Helm чарти
    └── django-app/           # Django застосунок
        ├── Chart.yaml
        ├── values.yaml
        └── templates/
```

## Встановлення та налаштування

### Передумови

- AWS CLI налаштований
- Terraform >= 1.0
- kubectl
- helm
- Docker (опціонально)

### Крок 1: Клонування репозиторію

### Крок 2: Налаштування змінних

Скопіюйте `terraform.tfvars.example` і налаштуйте:

```hcl
aws_region = "us-west-2"
project_name = "devops-project"
s3_bucket_name = "your-unique-terraform-bucket"
vpc_cidr = "10.0.0.0/16"
availability_zones = ["us-west-2a", "us-west-2b"]
cluster_name = "devops-eks-cluster"

# Для Jenkins/ArgoCD потрібні більші інстанси
node_instance_types = ["t3.small"]
node_desired_size = 2
```

### Крок 3: Створення інфраструктури

```bash
# Ініціалізація Terraform
terraform init

# Перевірка плану
terraform plan

# Застосування змін
terraform apply
```

**Увага**: Створення EKS кластера займе 10-15 хвилин.

### Крок 4: Налаштування kubectl

```bash
# Налаштування доступу до кластера
aws eks update-kubeconfig --region us-west-2 --name devops-eks-cluster

# Перевірка підключення
kubectl get nodes
```

### Крок 5: Доступ до сервісів

```bash
# Отримання URL сервісів
terraform output jenkins_url
terraform output argocd_url

# Отримання паролів
terraform output jenkins_admin_password
terraform output argocd_admin_password
```

## Використання

### Jenkins Pipeline

1. Відкрийте Jenkins UI за URL з terraform output
2. Увійдіть з логіном `admin` та паролем з output
3. Створіть новий Pipeline job
4. Налаштуйте Git repository з Jenkinsfile

Приклад Jenkinsfile:

```groovy
pipeline {
    agent {
        kubernetes {
            yaml """
apiVersion: v1
kind: Pod
spec:
  containers:
  - name: kaniko
    image: gcr.io/kaniko-project/executor:v1.9.0-debug
    command:
    - /busybox/cat
    tty: true
    volumeMounts:
    - name: docker-config
      mountPath: /kaniko/.docker
  - name: git
    image: alpine/git
    command:
    - cat
    tty: true
  volumes:
  - name: docker-config
    emptyDir: {}
"""
        }
    }
    
    stages {
        stage('Build') {
            steps {
                container('kaniko') {
                    script {
                        sh """
                        /kaniko/executor \\
                          --context=. \\
                          --dockerfile=Dockerfile \\
                          --destination=${ECR_REPOSITORY}:${BUILD_NUMBER}
                        """
                    }
                }
            }
        }
        
        stage('Update Helm Chart') {
            steps {
                container('git') {
                    script {
                        sh """
                        git clone https://github.com/your-username/your-helm-repo.git
                        cd your-helm-repo
                        sed -i 's/tag:.*/tag: ${BUILD_NUMBER}/' values.yaml
                        git add values.yaml
                        git commit -m "Update image tag to ${BUILD_NUMBER}"
                        git push
                        """
                    }
                }
            }
        }
    }
}
```

### ArgoCD Application

1. Відкрийте ArgoCD UI
2. Увійдіть з логіном `admin` та паролем з output
3. Створіть нову Application:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: django-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/your-username/your-helm-repo.git
    targetRevision: HEAD
    path: charts/django-app
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

## Моніторинг та обслуговування

### Перевірка статусу кластера

```bash
# Статус nodes
kubectl get nodes

# Статус pods
kubectl get pods --all-namespaces

# Jenkins статус
kubectl get pods -n jenkins

# ArgoCD статус
kubectl get pods -n argocd
```

### Логи сервісів

```bash
# Jenkins логи
kubectl logs -n jenkins deployment/jenkins

# ArgoCD логи
kubectl logs -n argocd deployment/argocd-server
```

## Очищення ресурсів

**Увага**: Це видалить всі створені ресурси та може призвести до втрати даних.

```bash
terraform destroy
```

## Вартість

Приблизна вартість інфраструктури на день:
- EKS Control Plane: $2.40/день
- EC2 instances (2x t3.small): ~$1.00/день
- RDS db.t3.micro: ~$0.50/день
- **Загалом: ~$4.00/день**

## Поширені проблеми

### Jenkins не запускається

Перевірте ресурси nodes:
```bash
kubectl describe nodes
kubectl get pods -n jenkins -o wide
```

Рішення: збільшіть розмір instances до t3.small або більше.

### ArgoCD не синхронізується

Перевірте права доступу до Git repository та налаштування SSH ключів.

### ECR authentication failed

```bash
# Оновіть Docker credentials
aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin <your-ecr-url>
```

## Контакти

За питаннями звертайтеся до команди DevOps або створюйте issue в цьому репозиторії.