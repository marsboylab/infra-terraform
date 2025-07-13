# RDS Module

이 모듈은 AWS RDS 인스턴스를 관리하기 위한 Terraform 모듈입니다. 다양한 데이터베이스 엔진을 지원하며, 고가용성, 모니터링, 보안을 고려한 설정을 제공합니다.

## 아키텍처

```
                    ┌─────────────────────────────────────────┐
                    │              AWS VPC                    │
                    │                                         │
                    │  ┌─────────────┐  ┌─────────────┐      │
                    │  │   Private   │  │   Private   │      │
                    │  │   Subnet    │  │   Subnet    │      │
                    │  │     AZ-A    │  │     AZ-B    │      │
                    │  │             │  │             │      │
                    │  │  ┌────────┐ │  │  ┌────────┐ │      │
                    │  │  │  RDS   │ │  │  │  RDS   │ │      │
                    │  │  │Primary │ │  │  │Standby │ │      │
                    │  │  │        │ │  │  │(Multi- │ │      │
                    │  │  │        │ │  │  │  AZ)   │ │      │
                    │  │  └────────┘ │  │  └────────┘ │      │
                    │  └─────────────┘  └─────────────┘      │
                    │                                         │
                    │  ┌─────────────┐  ┌─────────────┐      │
                    │  │   Public    │  │   Public    │      │
                    │  │   Subnet    │  │   Subnet    │      │
                    │  │     AZ-A    │  │     AZ-B    │      │
                    │  │             │  │             │      │
                    │  │  ┌────────┐ │  │  ┌────────┐ │      │
                    │  │  │  Read  │ │  │  │  Read  │ │      │
                    │  │  │Replica │ │  │  │Replica │ │      │
                    │  │  │   #1   │ │  │  │   #2   │ │      │
                    │  │  └────────┘ │  │  └────────┘ │      │
                    │  └─────────────┘  └─────────────┘      │
                    │                                         │
                    │  ┌─────────────────────────────────────┐│
                    │  │        Security Group               ││
                    │  │     - Port 3306/5432/1433          ││
                    │  │     - Inbound from allowed SGs      ││
                    │  │     - Inbound from allowed CIDRs    ││
                    │  └─────────────────────────────────────┘│
                    └─────────────────────────────────────────┘
                                      │
                                      │
                    ┌─────────────────────────────────────────┐
                    │         CloudWatch Monitoring           │
                    │                                         │
                    │  ┌─────────────┐  ┌─────────────┐      │
                    │  │   Alarms    │  │     Logs    │      │
                    │  │             │  │             │      │
                    │  │ • CPU       │  │ • Error     │      │
                    │  │ • Memory    │  │ • Slow Query│      │
                    │  │ • Storage   │  │ • General   │      │
                    │  │ • Latency   │  │ • Audit     │      │
                    │  │ • Connections│  │             │      │
                    │  └─────────────┘  └─────────────┘      │
                    │                                         │
                    │  ┌─────────────┐  ┌─────────────┐      │
                    │  │Performance  │  │Enhanced     │      │
                    │  │Insights     │  │Monitoring   │      │
                    │  └─────────────┘  └─────────────┘      │
                    └─────────────────────────────────────────┘
```

## 주요 기능

### 데이터베이스 엔진 지원

- **MySQL**: 8.0 (기본값)
- **PostgreSQL**: 14.x
- **MariaDB**: 10.6
- **Oracle Enterprise Edition**: 19c
- **SQL Server**: Express, Web, Standard, Enterprise Edition

### 고가용성 및 백업

- Multi-AZ 배포 지원
- 자동 백업 및 포인트 인 타임 복구
- 읽기 전용 복제본 (최대 5개)
- 스냅샷 기반 복원

### 보안

- VPC 내 배치
- 보안 그룹 자동 생성
- 저장 데이터 암호화 (KMS)
- 전송 중 데이터 암호화
- AWS Secrets Manager 통합

### 모니터링 및 로깅

- CloudWatch 통합 모니터링
- Performance Insights
- Enhanced Monitoring
- 자동 알람 설정
- 로그 스트리밍

### 성능 최적화

- 스토리지 자동 스케일링
- 다양한 스토리지 타입 지원 (gp3, io1, io2)
- 파라미터 그룹 최적화
- 커넥션 풀링 설정

## 사용 예제

### 기본 MySQL 설정

```hcl
module "mysql_database" {
  source = "./modules/rds"

  # 기본 설정
  name        = "myapp"
  environment = "dev"

  # 데이터베이스 설정
  engine         = "mysql"
  engine_version = "8.0.35"
  instance_class = "db.t3.medium"

  # 스토리지 설정
  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp3"
  storage_encrypted     = true

  # 네트워크 설정
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.database_subnet_ids

  # 보안 설정
  allowed_security_group_ids = [module.eks.cluster_security_group_id]

  # 백업 설정
  backup_retention_period = 7
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"

  # 모니터링
  monitoring_interval         = 60
  performance_insights_enabled = true
  create_cloudwatch_log_group = true

  tags = {
    Project = "myapp"
    Owner   = "devops-team"
  }
}
```

### 고가용성 PostgreSQL 설정

```hcl
module "postgresql_database" {
  source = "./modules/rds"

  # 기본 설정
  name        = "webapp"
  environment = "prod"

  # 데이터베이스 설정
  engine         = "postgres"
  engine_version = "14.10"
  instance_class = "db.r6g.xlarge"
  db_name        = "webapp_db"

  # 스토리지 설정
  allocated_storage     = 100
  max_allocated_storage = 1000
  storage_type          = "gp3"
  storage_encrypted     = true

  # 고가용성 설정
  multi_az = true

  # 읽기 전용 복제본
  create_read_replica    = true
  read_replica_count     = 2
  read_replica_multi_az  = true

  # 네트워크 설정
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.database_subnet_ids

  # 보안 설정
  allowed_security_group_ids = [
    module.eks.cluster_security_group_id,
    module.application.security_group_id
  ]

  # 백업 설정
  backup_retention_period = 30
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  deletion_protection    = true

  # 모니터링 및 알람
  monitoring_interval         = 15
  performance_insights_enabled = true
  create_cloudwatch_log_group = true
  create_alarms              = true

  alarm_actions = [aws_sns_topic.alerts.arn]

  # 파라미터 그룹 커스터마이징
  db_parameters = [
    {
      name  = "shared_preload_libraries"
      value = "pg_stat_statements,pg_hint_plan"
    },
    {
      name  = "log_statement"
      value = "all"
    },
    {
      name  = "log_min_duration_statement"
      value = "1000"
    }
  ]

  tags = {
    Project     = "webapp"
    Environment = "production"
    Owner       = "platform-team"
    Backup      = "required"
  }
}
```

### SQL Server Enterprise 설정

```hcl
module "sqlserver_database" {
  source = "./modules/rds"

  # 기본 설정
  name        = "erp"
  environment = "prod"

  # 데이터베이스 설정
  engine         = "sqlserver-ee"
  engine_version = "15.00.4322.2.v1"
  instance_class = "db.m5.2xlarge"

  # 스토리지 설정
  allocated_storage     = 500
  max_allocated_storage = 2000
  storage_type          = "io1"
  iops                  = 3000
  storage_encrypted     = true

  # 고가용성 설정
  multi_az = true

  # 네트워크 설정
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.database_subnet_ids

  # 보안 설정
  allowed_cidr_blocks = ["10.0.0.0/8"]

  # 백업 설정
  backup_retention_period = 35
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"
  deletion_protection    = true

  # 모니터링
  monitoring_interval         = 15
  performance_insights_enabled = true
  create_cloudwatch_log_group = true
  create_alarms              = true

  # 옵션 그룹 설정
  create_db_option_group = true
  db_options = [
    {
      option_name = "SQLSERVER_BACKUP_RESTORE"
      option_settings = [
        {
          name  = "IAM_ROLE_ARN"
          value = aws_iam_role.sqlserver_backup.arn
        }
      ]
    }
  ]

  tags = {
    Project     = "erp"
    Environment = "production"
    Owner       = "enterprise-team"
    Compliance  = "required"
  }
}
```

### 스냅샷에서 복원

```hcl
module "restored_database" {
  source = "./modules/rds"

  # 기본 설정
  name        = "restored-db"
  environment = "staging"

  # 데이터베이스 설정
  engine         = "mysql"
  instance_class = "db.t3.medium"

  # 스냅샷에서 복원
  snapshot_identifier = "myapp-prod-snapshot-2024-01-15"

  # 네트워크 설정
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.database_subnet_ids

  # 보안 설정
  allowed_security_group_ids = [module.staging_app.security_group_id]

  tags = {
    Project     = "myapp"
    Environment = "staging"
    Purpose     = "testing"
  }
}
```

### 포인트 인 타임 복구

```hcl
module "pitr_database" {
  source = "./modules/rds"

  # 기본 설정
  name        = "pitr-restore"
  environment = "dev"

  # 데이터베이스 설정
  engine         = "postgres"
  instance_class = "db.t3.medium"

  # 포인트 인 타임 복구
  restore_to_point_in_time = {
    source_db_instance_identifier = "webapp-prod"
    restore_time                  = "2024-01-15T10:30:00Z"
  }

  # 네트워크 설정
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.database_subnet_ids

  tags = {
    Project = "webapp"
    Purpose = "point-in-time-recovery"
  }
}
```

## 변수 설명

### 필수 변수

| 변수          | 타입           | 설명                      |
| ------------- | -------------- | ------------------------- |
| `name`        | `string`       | RDS 인스턴스 이름         |
| `environment` | `string`       | 환경 (dev, staging, prod) |
| `vpc_id`      | `string`       | VPC ID                    |
| `subnet_ids`  | `list(string)` | 서브넷 ID 목록            |

### 선택적 변수

#### 데이터베이스 설정

| 변수                    | 타입     | 기본값          | 설명                                |
| ----------------------- | -------- | --------------- | ----------------------------------- |
| `engine`                | `string` | `"mysql"`       | 데이터베이스 엔진                   |
| `engine_version`        | `string` | `null`          | 엔진 버전 (null인 경우 기본값 사용) |
| `instance_class`        | `string` | `"db.t3.micro"` | 인스턴스 클래스                     |
| `allocated_storage`     | `number` | `20`            | 할당된 스토리지 (GB)                |
| `max_allocated_storage` | `number` | `100`           | 최대 할당 스토리지 (GB)             |
| `storage_type`          | `string` | `"gp3"`         | 스토리지 타입                       |
| `storage_encrypted`     | `bool`   | `true`          | 스토리지 암호화 활성화              |

#### 네트워크 설정

| 변수                         | 타입           | 기본값  | 설명                |
| ---------------------------- | -------------- | ------- | ------------------- |
| `publicly_accessible`        | `bool`         | `false` | 퍼블릭 액세스 허용  |
| `allowed_cidr_blocks`        | `list(string)` | `[]`    | 허용된 CIDR 블록    |
| `allowed_security_group_ids` | `list(string)` | `[]`    | 허용된 보안 그룹 ID |

#### 고가용성 설정

| 변수                  | 타입     | 기본값  | 설명                  |
| --------------------- | -------- | ------- | --------------------- |
| `multi_az`            | `bool`   | `false` | Multi-AZ 배포         |
| `create_read_replica` | `bool`   | `false` | 읽기 전용 복제본 생성 |
| `read_replica_count`  | `number` | `1`     | 읽기 전용 복제본 개수 |

#### 백업 설정

| 변수                      | 타입     | 기본값                  | 설명                |
| ------------------------- | -------- | ----------------------- | ------------------- |
| `backup_retention_period` | `number` | `7`                     | 백업 보존 기간 (일) |
| `backup_window`           | `string` | `"03:00-04:00"`         | 백업 윈도우         |
| `maintenance_window`      | `string` | `"sun:04:00-sun:05:00"` | 유지보수 윈도우     |
| `deletion_protection`     | `bool`   | `true`                  | 삭제 보호           |

#### 모니터링 설정

| 변수                           | 타입     | 기본값  | 설명                        |
| ------------------------------ | -------- | ------- | --------------------------- |
| `monitoring_interval`          | `number` | `60`    | 모니터링 간격 (초)          |
| `performance_insights_enabled` | `bool`   | `false` | Performance Insights 활성화 |
| `create_cloudwatch_log_group`  | `bool`   | `false` | CloudWatch 로그 그룹 생성   |
| `create_alarms`                | `bool`   | `false` | CloudWatch 알람 생성        |

## 출력 값

### 주요 출력

| 출력                   | 설명                        |
| ---------------------- | --------------------------- |
| `db_instance_endpoint` | RDS 인스턴스 엔드포인트     |
| `db_instance_port`     | 데이터베이스 포트           |
| `db_instance_id`       | RDS 인스턴스 ID             |
| `db_instance_arn`      | RDS 인스턴스 ARN            |
| `db_name`              | 데이터베이스 이름           |
| `db_username`          | 마스터 사용자 이름          |
| `db_password`          | 마스터 비밀번호 (민감 정보) |
| `db_connection_string` | 연결 문자열 (민감 정보)     |

### 읽기 전용 복제본 출력

| 출력                     | 설명                             |
| ------------------------ | -------------------------------- |
| `read_replica_endpoints` | 읽기 전용 복제본 엔드포인트 목록 |
| `read_replica_instances` | 읽기 전용 복제본 인스턴스 정보   |

### 보안 및 네트워크 출력

| 출력                      | 설명                  |
| ------------------------- | --------------------- |
| `security_group_id`       | 보안 그룹 ID          |
| `db_subnet_group_name`    | DB 서브넷 그룹 이름   |
| `db_parameter_group_name` | DB 파라미터 그룹 이름 |
| `db_option_group_name`    | DB 옵션 그룹 이름     |

### 모니터링 출력

| 출력                        | 설명                      |
| --------------------------- | ------------------------- |
| `cloudwatch_alarms`         | CloudWatch 알람 정보      |
| `cloudwatch_log_group_name` | CloudWatch 로그 그룹 이름 |
| `monitoring_role_arn`       | 모니터링 역할 ARN         |

## 데이터베이스 엔진별 설정

### MySQL 8.0

```hcl
engine = "mysql"
engine_version = "8.0.35"
port = 3306

# 권장 파라미터
db_parameters = [
  {
    name  = "innodb_buffer_pool_size"
    value = "{DBInstanceClassMemory*3/4}"
  },
  {
    name  = "slow_query_log"
    value = "1"
  },
  {
    name  = "log_queries_not_using_indexes"
    value = "1"
  }
]
```

### PostgreSQL 14

```hcl
engine = "postgres"
engine_version = "14.10"
port = 5432

# 권장 파라미터
db_parameters = [
  {
    name  = "shared_preload_libraries"
    value = "pg_stat_statements"
  },
  {
    name  = "log_statement"
    value = "all"
  },
  {
    name  = "log_min_duration_statement"
    value = "1000"
  }
]
```

### MariaDB 10.6

```hcl
engine = "mariadb"
engine_version = "10.6.16"
port = 3306

# 권장 파라미터
db_parameters = [
  {
    name  = "innodb_buffer_pool_size"
    value = "{DBInstanceClassMemory*3/4}"
  },
  {
    name  = "query_cache_type"
    value = "1"
  }
]
```

## 보안 모범 사례

### 1. 네트워크 보안

```hcl
# 프라이빗 서브넷 배치
subnet_ids = module.vpc.database_subnet_ids

# 퍼블릭 액세스 비활성화
publicly_accessible = false

# 특정 보안 그룹만 허용
allowed_security_group_ids = [
  module.application.security_group_id
]
```

### 2. 암호화

```hcl
# 저장 데이터 암호화
storage_encrypted = true
kms_key_id = aws_kms_key.rds.arn

# Performance Insights 암호화
performance_insights_enabled = true
performance_insights_kms_key_id = aws_kms_key.rds.arn
```

### 3. 접근 제어

```hcl
# AWS Secrets Manager 사용
manage_master_user_password = true
master_user_secret_kms_key_id = aws_kms_key.secrets.arn

# 삭제 보호
deletion_protection = true
skip_final_snapshot = false
```

## 성능 튜닝 가이드

### 1. 인스턴스 클래스 선택

```hcl
# 개발 환경
instance_class = "db.t3.micro"

# 스테이징 환경
instance_class = "db.t3.medium"

# 프로덕션 환경 (범용)
instance_class = "db.m6g.xlarge"

# 프로덕션 환경 (메모리 최적화)
instance_class = "db.r6g.2xlarge"

# 프로덕션 환경 (I/O 최적화)
instance_class = "db.x2g.large"
```

### 2. 스토리지 최적화

```hcl
# 범용 워크로드
storage_type = "gp3"
storage_throughput = 125

# 고성능 워크로드
storage_type = "io1"
iops = 3000

# 최신 고성능 워크로드
storage_type = "io2"
iops = 4000
```

### 3. 파라미터 튜닝

```hcl
# MySQL 최적화
db_parameters = [
  {
    name  = "innodb_buffer_pool_size"
    value = "{DBInstanceClassMemory*3/4}"
  },
  {
    name  = "innodb_log_file_size"
    value = "256MB"
  },
  {
    name  = "max_connections"
    value = "1000"
  }
]

# PostgreSQL 최적화
db_parameters = [
  {
    name  = "shared_buffers"
    value = "{DBInstanceClassMemory/4}"
  },
  {
    name  = "effective_cache_size"
    value = "{DBInstanceClassMemory*3/4}"
  },
  {
    name  = "work_mem"
    value = "4MB"
  }
]
```

## 비용 최적화

### 1. 인스턴스 크기 조정

```hcl
# 개발 환경에서는 작은 인스턴스 사용
instance_class = var.environment == "dev" ? "db.t3.micro" : "db.t3.large"

# 스토리지 자동 스케일링 활용
max_allocated_storage = var.allocated_storage * 5
```

### 2. 백업 최적화

```hcl
# 환경별 백업 보존 기간
backup_retention_period = var.environment == "prod" ? 30 : 7

# 개발 환경에서는 백업 비활성화
backup_retention_period = var.environment == "dev" ? 0 : 7
```

### 3. 모니터링 최적화

```hcl
# 환경별 모니터링 간격
monitoring_interval = var.environment == "prod" ? 15 : 60

# 개발 환경에서는 Performance Insights 비활성화
performance_insights_enabled = var.environment != "dev"
```

## 모니터링 및 알람

### 1. 기본 알람

```hcl
create_alarms = true
alarm_actions = [aws_sns_topic.rds_alerts.arn]

# 임계값 설정
cpu_utilization_threshold = 80
database_connections_threshold = 80
free_storage_space_threshold = 2000000000 # 2GB
```

### 2. CloudWatch 로그

```hcl
create_cloudwatch_log_group = true
enabled_cloudwatch_logs_exports = ["error", "general", "slow-query"]
cloudwatch_log_group_retention_in_days = 7
```

### 3. Performance Insights

```hcl
performance_insights_enabled = true
performance_insights_retention_period = 7
performance_insights_kms_key_id = aws_kms_key.rds.arn
```

## 장애 복구

### 1. 자동 백업

```hcl
backup_retention_period = 30
backup_window = "03:00-04:00"
copy_tags_to_snapshot = true
```

### 2. Multi-AZ 배포

```hcl
multi_az = true
```

### 3. 읽기 전용 복제본

```hcl
create_read_replica = true
read_replica_count = 2
read_replica_multi_az = true
```

## 문제 해결

### 1. 연결 문제

```bash
# 보안 그룹 확인
aws ec2 describe-security-groups --group-ids sg-xxxxx

# 서브넷 그룹 확인
aws rds describe-db-subnet-groups --db-subnet-group-name myapp-dev-db-subnet-group
```

### 2. 성능 문제

```bash
# Performance Insights 확인
aws rds describe-db-instances --db-instance-identifier myapp-dev

# CloudWatch 메트릭 확인
aws cloudwatch get-metric-statistics \
  --namespace AWS/RDS \
  --metric-name CPUUtilization \
  --dimensions Name=DBInstanceIdentifier,Value=myapp-dev \
  --start-time 2024-01-01T00:00:00Z \
  --end-time 2024-01-01T23:59:59Z \
  --period 300 \
  --statistics Average
```

### 3. 백업 및 복구

```bash
# 스냅샷 생성
aws rds create-db-snapshot \
  --db-instance-identifier myapp-dev \
  --db-snapshot-identifier myapp-dev-manual-snapshot

# 포인트 인 타임 복구
aws rds restore-db-instance-to-point-in-time \
  --source-db-instance-identifier myapp-prod \
  --target-db-instance-identifier myapp-restored \
  --restore-time 2024-01-01T12:00:00Z
```

## 라이선스

이 모듈은 MIT 라이선스 하에 제공됩니다.

## 기여

버그 리포트, 기능 요청, 풀 리퀘스트를 환영합니다. 기여하기 전에 CONTRIBUTING.md를 확인해 주세요.

## 지원

질문이나 지원이 필요한 경우:

1. GitHub Issues에 문제를 제출하세요
2. 팀 Slack 채널 #infrastructure에 메시지를 보내세요
3. 이메일: devops@company.com
