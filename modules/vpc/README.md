# VPC Module

이 모듈은 AWS VPC (Virtual Private Cloud)와 관련된 모든 네트워크 인프라를 생성합니다.

## 주요 기능

- **VPC**: 사용자 정의 가상 네트워크 환경
- **서브넷**: 퍼블릭, 프라이빗, 데이터베이스 서브넷 구성
- **NAT 게이트웨이/인스턴스**: 프라이빗 서브넷의 아웃바운드 인터넷 접근
- **인터넷 게이트웨이**: 퍼블릭 서브넷의 인터넷 접근
- **라우팅 테이블**: 네트워크 트래픽 라우팅 관리
- **VPC 엔드포인트**: AWS 서비스에 대한 프라이빗 액세스
- **보안 그룹**: 네트워크 보안 규칙
- **Network ACL**: 서브넷 레벨 네트워크 액세스 제어
- **VPC Flow Logs**: 네트워크 트래픽 로깅
- **데이터베이스 서브넷 그룹**: RDS, ElastiCache 등을 위한 서브넷 그룹

## 아키텍처

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                    VPC                                          │
│                              10.0.0.0/16                                       │
├─────────────────────────────────────────────────────────────────────────────────┤
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────────┐ │
│  │                             Public Subnets                                  │ │
│  │  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐        │ │
│  │  │   10.0.0.0/24   │    │   10.0.1.0/24   │    │   10.0.2.0/24   │        │ │
│  │  │      AZ-a       │    │      AZ-b       │    │      AZ-c       │        │ │
│  │  │                 │    │                 │    │                 │        │ │
│  │  │   NAT Gateway   │    │   NAT Gateway   │    │   NAT Gateway   │        │ │
│  │  │   ELB/ALB       │    │   ELB/ALB       │    │   ELB/ALB       │        │ │
│  │  └─────────────────┘    └─────────────────┘    └─────────────────┘        │ │
│  └─────────────────────────────────────────────────────────────────────────────┘ │
│                                      │                                          │
│                              Internet Gateway                                   │
│                                      │                                          │
│  ┌─────────────────────────────────────────────────────────────────────────────┐ │
│  │                            Private Subnets                                  │ │
│  │  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐        │ │
│  │  │  10.0.10.0/24   │    │  10.0.11.0/24   │    │  10.0.12.0/24   │        │ │
│  │  │      AZ-a       │    │      AZ-b       │    │      AZ-c       │        │ │
│  │  │                 │    │                 │    │                 │        │ │
│  │  │   EKS Nodes     │    │   EKS Nodes     │    │   EKS Nodes     │        │ │
│  │  │   App Servers   │    │   App Servers   │    │   App Servers   │        │ │
│  │  └─────────────────┘    └─────────────────┘    └─────────────────┘        │ │
│  └─────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────────┐ │
│  │                            Database Subnets                                 │ │
│  │  ┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐        │ │
│  │  │  10.0.20.0/24   │    │  10.0.21.0/24   │    │  10.0.22.0/24   │        │ │
│  │  │      AZ-a       │    │      AZ-b       │    │      AZ-c       │        │ │
│  │  │                 │    │                 │    │                 │        │ │
│  │  │     RDS         │    │     RDS         │    │     RDS         │        │ │
│  │  │ ElastiCache     │    │ ElastiCache     │    │ ElastiCache     │        │ │
│  │  └─────────────────┘    └─────────────────┘    └─────────────────┘        │ │
│  └─────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────────┐ │
│  │                             VPC Endpoints                                   │ │
│  │                                                                             │ │
│  │  S3 Gateway    DynamoDB Gateway    EC2 Interface    ECR Interface          │ │
│  │  SSM Interface    Logs Interface    EKS Interface                          │ │
│  └─────────────────────────────────────────────────────────────────────────────┘ │
│                                                                                 │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## 사용 예제

### 기본 사용법

```hcl
module "vpc" {
  source = "./modules/vpc"

  environment  = "dev"
  region       = "ap-northeast-2"
  project_name = "my-project"

  vpc_cidr = "10.0.0.0/16"

  tags = {
    Environment = "dev"
    Project     = "my-project"
    Owner       = "platform-team"
  }
}
```

### 고급 설정

```hcl
module "vpc" {
  source = "./modules/vpc"

  environment  = "prod"
  region       = "ap-northeast-2"
  project_name = "my-project"
  vpc_name     = "production-vpc"

  # VPC 설정
  vpc_cidr             = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  # 가용 영역 설정
  availability_zones = ["ap-northeast-2a", "ap-northeast-2b", "ap-northeast-2c"]

  # 서브넷 CIDR 사용자 정의
  public_subnet_cidrs   = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnet_cidrs  = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  database_subnet_cidrs = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]

  # NAT 게이트웨이 설정
  enable_nat_gateway     = true
  one_nat_gateway_per_az = true
  single_nat_gateway     = false

  # VPC 엔드포인트 설정
  enable_vpc_endpoints = true

  # Flow Logs 설정
  enable_flow_logs                   = true
  flow_logs_destination_type         = "cloud-watch-logs"
  flow_logs_retention_in_days        = 30

  # 보안 그룹 설정
  manage_default_security_group = true
  default_security_group_ingress = []
  default_security_group_egress = [
    {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  # 추가 태그
  tags = {
    Environment = "prod"
    Project     = "my-project"
    Owner       = "platform-team"
    CostCenter  = "engineering"
  }

  vpc_tags = {
    Description = "Production VPC for my-project"
  }

  public_subnet_tags = {
    Type = "public"
    "kubernetes.io/role/elb" = "1"
  }

  private_subnet_tags = {
    Type = "private"
    "kubernetes.io/role/internal-elb" = "1"
  }
}
```

### 비용 최적화 설정 (NAT 인스턴스 사용)

```hcl
module "vpc" {
  source = "./modules/vpc"

  environment  = "dev"
  region       = "ap-northeast-2"
  project_name = "my-project"

  vpc_cidr = "10.0.0.0/16"

  # NAT 인스턴스 사용 (비용 절약)
  enable_nat_gateway = false
  single_nat_gateway = true

  # 기본 VPC 엔드포인트만 사용
  enable_vpc_endpoints = false

  tags = {
    Environment = "dev"
    Project     = "my-project"
    CostOptimized = "true"
  }
}
```

### 커스텀 VPC 엔드포인트 설정

```hcl
module "vpc" {
  source = "./modules/vpc"

  environment  = "prod"
  region       = "ap-northeast-2"
  project_name = "my-project"

  vpc_cidr = "10.0.0.0/16"

  # 커스텀 VPC 엔드포인트
  vpc_endpoints = {
    lambda = {
      service             = "lambda"
      vpc_endpoint_type   = "Interface"
      subnet_ids          = []  # 프라이빗 서브넷 사용
      security_group_ids  = []  # 기본 보안 그룹 사용
      route_table_ids     = []
      policy_statements   = [
        {
          effect = "Allow"
          actions = [
            "lambda:InvokeFunction"
          ]
          resources = ["*"]
        }
      ]
    }
  }

  tags = {
    Environment = "prod"
    Project     = "my-project"
  }
}
```

## 입력 변수

### 필수 변수

| 변수          | 타입     | 설명                       |
| ------------- | -------- | -------------------------- |
| `environment` | `string` | 환경 이름 (dev, stg, prod) |
| `region`      | `string` | AWS 리전                   |

### 선택적 변수

| 변수                   | 타입           | 기본값          | 설명                            |
| ---------------------- | -------------- | --------------- | ------------------------------- |
| `project_name`         | `string`       | `"infra"`       | 프로젝트 이름                   |
| `vpc_cidr`             | `string`       | `"10.0.0.0/16"` | VPC CIDR 블록                   |
| `vpc_name`             | `string`       | `""`            | VPC 이름 (비어있으면 자동 생성) |
| `availability_zones`   | `list(string)` | `[]`            | 가용 영역 목록                  |
| `az_count`             | `number`       | `2`             | 사용할 가용 영역 수             |
| `enable_nat_gateway`   | `bool`         | `true`          | NAT 게이트웨이 활성화           |
| `single_nat_gateway`   | `bool`         | `false`         | 단일 NAT 게이트웨이 사용        |
| `enable_vpc_endpoints` | `bool`         | `true`          | VPC 엔드포인트 활성화           |
| `enable_flow_logs`     | `bool`         | `false`         | VPC Flow Logs 활성화            |
| `tags`                 | `map(string)`  | `{}`            | 공통 태그                       |

## 출력 값

### VPC 정보

| 출력             | 설명          |
| ---------------- | ------------- |
| `vpc_id`         | VPC ID        |
| `vpc_arn`        | VPC ARN       |
| `vpc_cidr_block` | VPC CIDR 블록 |
| `vpc_name`       | VPC 이름      |

### 서브넷 정보

| 출력                       | 설명                        |
| -------------------------- | --------------------------- |
| `public_subnet_ids`        | 퍼블릭 서브넷 ID 목록       |
| `private_subnet_ids`       | 프라이빗 서브넷 ID 목록     |
| `database_subnet_ids`      | 데이터베이스 서브넷 ID 목록 |
| `database_subnet_group_id` | 데이터베이스 서브넷 그룹 ID |

### 네트워크 게이트웨이 정보

| 출력                     | 설명                          |
| ------------------------ | ----------------------------- |
| `igw_id`                 | 인터넷 게이트웨이 ID          |
| `nat_gateway_ids`        | NAT 게이트웨이 ID 목록        |
| `nat_gateway_public_ips` | NAT 게이트웨이 퍼블릭 IP 목록 |

### 라우팅 테이블 정보

| 출력                       | 설명                               |
| -------------------------- | ---------------------------------- |
| `public_route_table_id`    | 퍼블릭 라우팅 테이블 ID            |
| `private_route_table_ids`  | 프라이빗 라우팅 테이블 ID 목록     |
| `database_route_table_ids` | 데이터베이스 라우팅 테이블 ID 목록 |

## 사전 요구사항

1. **AWS 계정**: 적절한 권한을 가진 AWS 계정
2. **Terraform**: 버전 1.0 이상
3. **AWS CLI**: 인증 설정 완료

## 네트워크 설계 가이드

### CIDR 블록 계획

```
VPC: 10.0.0.0/16 (65,536 IPs)
├── Public Subnets: 10.0.0.0/20 (4,096 IPs)
│   ├── AZ-a: 10.0.0.0/24 (256 IPs)
│   ├── AZ-b: 10.0.1.0/24 (256 IPs)
│   └── AZ-c: 10.0.2.0/24 (256 IPs)
├── Private Subnets: 10.0.16.0/20 (4,096 IPs)
│   ├── AZ-a: 10.0.16.0/24 (256 IPs)
│   ├── AZ-b: 10.0.17.0/24 (256 IPs)
│   └── AZ-c: 10.0.18.0/24 (256 IPs)
└── Database Subnets: 10.0.32.0/20 (4,096 IPs)
    ├── AZ-a: 10.0.32.0/24 (256 IPs)
    ├── AZ-b: 10.0.33.0/24 (256 IPs)
    └── AZ-c: 10.0.34.0/24 (256 IPs)
```

### 보안 고려사항

1. **네트워크 분리**: 퍼블릭, 프라이빗, 데이터베이스 서브넷 분리
2. **최소 권한 원칙**: 필요한 트래픽만 허용
3. **VPC 엔드포인트**: AWS 서비스 접근 시 인터넷 우회
4. **Flow Logs**: 네트워크 트래픽 모니터링

### 고가용성 설계

1. **다중 AZ**: 최소 2개 이상의 가용 영역 사용
2. **NAT 게이트웨이**: 각 AZ별 NAT 게이트웨이 배치
3. **로드 밸런서**: 여러 AZ에 걸친 로드 밸런싱

## 비용 최적화

### NAT 게이트웨이 비용 절약

```hcl
# 단일 NAT 게이트웨이 사용
single_nat_gateway = true

# 또는 NAT 인스턴스 사용
enable_nat_gateway = false
```

### VPC 엔드포인트 최적화

```hcl
# 필수 엔드포인트만 활성화
enable_vpc_endpoints = true
vpc_endpoints = {
  s3 = {
    service = "s3"
    vpc_endpoint_type = "Gateway"
    # ... 설정
  }
}
```

## 모니터링 및 로깅

### VPC Flow Logs 활성화

```hcl
enable_flow_logs = true
flow_logs_destination_type = "cloud-watch-logs"
flow_logs_retention_in_days = 30
```

### CloudWatch 메트릭

- NAT 게이트웨이 데이터 전송량
- VPC 엔드포인트 사용량
- 네트워크 ACL 규칙 적중률

## 문제 해결

### 일반적인 문제

1. **서브넷 IP 고갈**

   - CIDR 블록 크기 확인
   - 서브넷 사용률 모니터링

2. **NAT 게이트웨이 연결 실패**

   - 라우팅 테이블 확인
   - 인터넷 게이트웨이 상태 확인

3. **VPC 엔드포인트 접근 불가**
   - 보안 그룹 규칙 확인
   - DNS 설정 확인

### 로그 확인

```bash
# VPC Flow Logs 확인
aws logs describe-log-groups --log-group-name-prefix "/aws/vpc"

# NAT 게이트웨이 상태 확인
aws ec2 describe-nat-gateways --region ap-northeast-2

# VPC 엔드포인트 상태 확인
aws ec2 describe-vpc-endpoints --region ap-northeast-2
```

## 업그레이드 가이드

### 기존 VPC 마이그레이션

1. **현재 구성 백업**
2. **단계별 마이그레이션**
3. **검증 및 테스트**
4. **DNS 업데이트**

### 버전 업그레이드

모듈 버전 업그레이드 시 주의사항:

- 변경사항 확인
- 테스트 환경에서 먼저 적용
- 롤백 계획 수립

## 참고 자료

- [AWS VPC 사용 설명서](https://docs.aws.amazon.com/vpc/)
- [AWS NAT Gateway 가이드](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-gateway.html)
- [AWS VPC Endpoints](https://docs.aws.amazon.com/vpc/latest/privatelink/vpc-endpoints.html)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

## 지원

문제가 발생하거나 기능 요청이 있으시면 이슈를 생성해 주세요.
