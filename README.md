# Універсальний Terraform RDS модуль

Гнучкий Terraform модуль для створення AWS RDS або Aurora кластерів з повним набором налаштувань для production-ready баз даних.

## Особливості модуля

- 🔄 **Універсальність**: Підтримка RDS instance або Aurora cluster через параметр `use_aurora`
- 🔒 **Безпека**: Security Groups, шифрування, приватні підмережі
- ⚙️ **Гнучкість**: Parameter Groups для тонкого налаштування БД
- 📊 **Моніторинг**: Enhanced Monitoring для production середовищ
- 🔧 **Автоматизація**: Автоматичні backup, maintenance windows
- 🏗️ **Масштабування**: Multi-AZ для HA, Aurora читаючі репліки

## Структура модуля

```
modules/rds/
├── shared.tf          # Спільні ресурси (Security Groups, Subnet Groups)
├── rds.tf             # RDS instance логіка
├── aurora.tf          # Aurora cluster логіка
├── variables.tf       # Змінні модуля
└── outputs.tf         # Виходи модуля
```

## Підтримувані конфігурації

| Компонент | RDS Instance | Aurora Cluster |
|-----------|--------------|----------------|
| **Engines** | PostgreSQL, MySQL | PostgreSQL, MySQL |
| **HA** | Multi-AZ | Multi-AZ (автоматично) |
| **Backup** | Automated Backups | Automated Backups |
| **Scaling** | Vertical | Horizontal + Vertical |
| **Read Replicas** | Manual | Автоматичні |

## Швидкий старт

### Базова RDS instance

```hcl
module "rds" {
  source = "./modules/rds"
  
  project_name = "my-app"
  vpc_id = "vpc-12345678"
  private_subnet_ids = ["subnet-1", "subnet-2"]
  
  use_aurora = false
  
  engine = "postgres"
  engine_version = "15.8"
  instance_class = "db.t3.micro"
  
  database_name = "appdb"
  username = "dbadmin"
}
```

### Aurora Cluster

```hcl
module "rds" {
  source = "./modules/rds"
  
  project_name = "my-app"
  vpc_id = "vpc-12345678"
  private_subnet_ids = ["subnet-1", "subnet-2"]
  
  use_aurora = true
  aurora_instance_count = 2
  
  engine = "aurora-postgresql"
  engine_version = "15.8"
  instance_class = "db.t3.medium"
  
  database_name = "appdb"
  username = "dbadmin"
}
```

## Параметри модуля

### Обов'язкові параметри

| Параметр | Опис | Тип |
|----------|------|-----|
| `project_name` | Назва проекту | `string` |
| `vpc_id` | ID VPC | `string` |
| `private_subnet_ids` | ID приватних підмереж | `list(string)` |

### Основні параметри

| Параметр | Опис | За замовчуванням |
|----------|------|------------------|
| `use_aurora` | Використовувати Aurora замість RDS | `false` |
| `engine` | Движок БД (postgres/mysql) | `"postgres"` |
| `engine_version` | Версія движка | `"15.8"` |
| `instance_class` | Клас інстанса | `"db.t3.micro"` |
| `database_name` | Ім'я БД | `"appdb"` |
| `username` | Користувач БД | `"dbadmin"` |

### Параметри зберігання (тільки RDS)

| Параметр | Опис | За замовчуванням |
|----------|------|------------------|
| `allocated_storage` | Початковий розмір (GB) | `20` |
| `max_allocated_storage` | Максимальний розмір (GB) | `100` |
| `storage_type` | Тип сховища | `"gp2"` |
| `storage_encrypted` | Шифрування | `true` |

### Параметри високої доступності

| Параметр | Опис | За замовчуванням |
|----------|------|------------------|
| `multi_az` | Multi-AZ (тільки RDS) | `false` |
| `aurora_instance_count` | К-сть Aurora інстансів | `1` |

### Параметри backup та обслуговування

| Параметр | Опис | За замовчуванням |
|----------|------|------------------|
| `backup_retention_period` | Період зберігання backup (дні) | `7` |
| `backup_window` | Вікно backup | `"03:00-04:00"` |
| `maintenance_window` | Вікно обслуговування | `"sun:04:00-sun:05:00"` |

## Приклади використання

### Production PostgreSQL з Multi-AZ

```hcl
module "production_db" {
  source = "./modules/rds"
  
  project_name = "production"
  vpc_id = var.vpc_id
  private_subnet_ids = var.private_subnet_ids
  
  # RDS конфігурація
  use_aurora = false
  engine = "postgres"
  engine_version = "15.8"
  instance_class = "db.r5.xlarge"
  
  # База даних
  database_name = "production_app"
  username = "app_user"
  
  # Зберігання
  allocated_storage = 100
  max_allocated_storage = 1000
  storage_type = "gp3"
  storage_encrypted = true
  
  # Висока доступність
  multi_az = true
  
  # Backup
  backup_retention_period = 30
  backup_window = "03:00-04:00"
  maintenance_window = "sun:04:00-sun:06:00"
  
  # Моніторинг
  monitoring_interval = 60
  
  # Безпека
  deletion_protection = true
  skip_final_snapshot = false
  
  # Кастомні параметри
  db_parameters = [
    {
      name  = "shared_preload_libraries"
      value = "pg_stat_statements,pg_hint_plan"
    },
    {
      name  = "max_connections"
      value = "200"
    },
    {
      name  = "work_mem"
      value = "32MB"
    }
  ]
}
```

### Aurora PostgreSQL кластер

```hcl
module "aurora_cluster" {
  source = "./modules/rds"
  
  project_name = "aurora-app"
  vpc_id = var.vpc_id
  private_subnet_ids = var.private_subnet_ids
  
  # Aurora конфігурація
  use_aurora = true
  aurora_instance_count = 3
  
  engine = "aurora-postgresql"
  engine_version = "15.8"
  instance_class = "db.r5.large"
  
  # База даних
  database_name = "cluster_app"
  username = "cluster_user"
  
  # Backup
  backup_retention_period = 14
  
  # Моніторинг
  monitoring_interval = 30
  
  # Параметри кластера
  db_parameters = [
    {
      name  = "log_statement"
      value = "all"
    },
    {
      name  = "log_min_duration_statement"
      value = "1000"
    }
  ]
}
```

### MySQL для розробки

```hcl
module "dev_mysql" {
  source = "./modules/rds"
  
  project_name = "development"
  vpc_id = var.vpc_id
  private_subnet_ids = var.private_subnet_ids
  
  # MySQL конфігурація
  use_aurora = false
  engine = "mysql"
  engine_version = "8.0.35"
  instance_class = "db.t3.micro"
  port = 3306
  
  # База даних
  database_name = "devapp"
  username = "developer"
  
  # Розробницькі налаштування
  multi_az = false
  deletion_protection = false
  skip_final_snapshot = true
  backup_retention_period = 1
  
  # MySQL параметри
  parameter_group_family = "mysql8.0"
  db_parameters = [
    {
      name  = "innodb_buffer_pool_size"
      value = "{DBInstanceClassMemory*3/4}"
    }
  ]
}
```

## Виходи модуля

| Вихід | Опис |
|-------|------|
| `endpoint` | Endpoint для підключення до БД |
| `reader_endpoint` | Reader endpoint (тільки Aurora) |
| `port` | Порт БД |
| `database_name` | Ім'я бази даних |
| `username` | Ім'я користувача |
| `password` | Пароль (sensitive) |
| `connection_string` | Строка підключення (sensitive) |
| `security_group_id` | ID Security Group |
| `subnet_group_name` | Ім'я Subnet Group |

### Приклад використання виходів

```hcl
# Використання в додатку
resource "kubernetes_secret" "db_credentials" {
  metadata {
    name = "db-credentials"
  }
  
  data = {
    host     = module.rds.endpoint
    port     = tostring(module.rds.port)
    database = module.rds.database_name
    username = module.rds.username
    password = module.rds.password
  }
  
  type = "Opaque"
}
```

## Моніторинг та алерти

### CloudWatch метрики

Модуль автоматично налаштовує Enhanced Monitoring, який збирає:
- CPU використання
- Пам'ять
- З'єднання до БД
- IOPS операції
- Latency

### Приклад налаштування алертів

```hcl
resource "aws_cloudwatch_metric_alarm" "database_cpu" {
  alarm_name          = "${module.rds.db_instance_identifier}-high-cpu"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = "300"
  statistic           = "Average"
  threshold           = "80"
  alarm_description   = "This metric monitors rds cpu utilization"
  
  dimensions = {
    DBInstanceIdentifier = module.rds.db_instance_identifier
  }
}
```

## Безпека

### Security Group правила

Модуль створює Security Group, який:
- Дозволяє вхідні з'єднання тільки з VPC CIDR
- Блокує всі інші вхідні з'єднання
- Дозволяє всі вихідні з'єднання

### Шифрування

- **At-rest**: Увімкнене за замовчуванням
- **In-transit**: Підтримується (налаштовується в додатку)

### Мережева ізоляція

- БД розгортається тільки в приватних підмережах
- Відсутній публічний доступ

## Вартість оптимізація

### Поради для зменшення витрат

1. **Розмір інстанса**: Використовуйте t3.micro для dev/test
2. **Multi-AZ**: Вимикайте для непродукційних середовищ
3. **Backup retention**: 1 день для розробки, 7-30 для продакшену
4. **Monitoring**: Вимикайте Enhanced Monitoring для dev

### Приблизна вартість (us-west-2)

| Конфігурація | Щомісяця |
|--------------|----------|
| db.t3.micro (dev) | ~$15 |
| db.t3.small (staging) | ~$30 |
| db.r5.large (prod) | ~$150 |
| Aurora (2x db.r5.large) | ~$300 |

## Застосування команд

### Створення інфраструктури

```bash
# Ініціалізація
terraform init

# Планування
terraform plan -var="use_aurora=false"

# Застосування
terraform apply
```

### Перемикання між RDS та Aurora

```bash
# RDS → Aurora (потребує пересоздання)
terraform apply -var="use_aurora=true"

# Aurora → RDS (потребує пересоздання)
terraform apply -var="use_aurora=false"
```

### Масштабування

```bash
# Збільшення розміру інстанса
terraform apply -var="instance_class=db.r5.large"

# Додавання читаючих реплік Aurora
terraform apply -var="aurora_instance_count=3"
```

## Усунення несправностей

### Логи CloudWatch

```bash
# Перегляд помилкових логів
aws logs describe-log-groups --log-group-name-prefix="/aws/rds/instance"
```

### Моніторинг метрик

```bash
# CPU використання
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name CPUUtilization \
  --dimensions Name=DBInstanceIdentifier,Value=<your-db-identifier> \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-02T00:00:00Z \
  --period 3600 \
  --statistics Average
```

## Міграція даних

### Між RDS інстансами

```bash
# Dump з старої БД
pg_dump -h old-endpoint -U username dbname > backup.sql

# Restore в нову БД
psql -h new-endpoint -U username dbname < backup.sql
```

### RDS до Aurora

Використовуйте AWS Database Migration Service (DMS) для zero-downtime міграції.

## Відомі обмеження

1. **Перемикання RDS ↔ Aurora** потребує пересоздання ресурсів
2. **Parameter Groups** не можна змінювати після створення
3. **Engine versions** можуть бути недоступні в деяких регіонах
4. **Storage type** змінити можна тільки до більш продуктивного

## Контакти

За питаннями щодо модуля звертайтеся до команди Platform Engineering або створюйте issue в репозиторії.