# Route53 Module

이 모듈은 AWS Route53 DNS 서비스를 포괄적으로 관리하기 위한 Terraform 모듈입니다. 호스팅 존, DNS 레코드, 헬스체크, Route53 Resolver, DNSSEC, 도메인 등록 등을 지원합니다.

## 아키텍처

```
                    ┌─────────────────────────────────────────┐
                    │                Internet                 │
                    └─────────────┬───────────────────────────┘
                                  │
                    ┌─────────────────────────────────────────┐
                    │            Route53 Service              │
                    │                                         │
                    │  ┌─────────────┐  ┌─────────────┐      │
                    │  │   Public    │  │   Private   │      │
                    │  │ Hosted Zone │  │ Hosted Zone │      │
                    │  │             │  │             │      │
                    │  │ • A Records │  │ • A Records │      │
                    │  │ • CNAME     │  │ • CNAME     │      │
                    │  │ • MX        │  │ • SRV       │      │
                    │  │ • TXT       │  │ • TXT       │      │
                    │  │ • ALIAS     │  │ • ALIAS     │      │
                    │  └─────────────┘  └─────────────┘      │
                    │                                         │
                    │  ┌─────────────┐  ┌─────────────┐      │
                    │  │   DNSSEC    │  │ Health      │      │
                    │  │             │  │ Checks      │      │
                    │  │ • KMS Keys  │  │             │      │
                    │  │ • Key Sign  │  │ • HTTP/HTTPS│      │
                    │  │ • DS Record │  │ • TCP       │      │
                    │  │ • DNSKEY    │  │ • Calculated│      │
                    │  └─────────────┘  └─────────────┘      │
                    └─────────────────────────────────────────┘
                                  │
                    ┌─────────────────────────────────────────┐
                    │               AWS VPC                   │
                    │                                         │
                    │  ┌─────────────┐  ┌─────────────┐      │
                    │  │  Resolver   │  │  Resolver   │      │
                    │  │  Endpoint   │  │   Rules     │      │
                    │  │  (Inbound)  │  │             │      │
                    │  │             │  │ • Forward   │      │
                    │  │ ┌─────────┐ │  │ • System    │      │
                    │  │ │   DNS   │ │  │ • Recursive │      │
                    │  │ │ Port 53 │ │  │             │      │
                    │  │ └─────────┘ │  └─────────────┘      │
                    │  └─────────────┘                       │
                    │                                         │
                    │  ┌─────────────┐  ┌─────────────┐      │
                    │  │  Resolver   │  │  Firewall   │      │
                    │  │  Endpoint   │  │   Rules     │      │
                    │  │ (Outbound)  │  │             │      │
                    │  │             │  │ • Block     │      │
                    │  │ ┌─────────┐ │  │ • Allow     │      │
                    │  │ │External │ │  │ • Alert     │      │
                    │  │ │   DNS   │ │  │             │      │
                    │  │ └─────────┘ │  └─────────────┘      │
                    │  └─────────────┘                       │
                    └─────────────────────────────────────────┘
                                  │
                    ┌─────────────────────────────────────────┐
                    │         CloudWatch Monitoring           │
                    │                                         │
                    │  ┌─────────────┐  ┌─────────────┐      │
                    │  │Query Logging│  │   Alarms    │      │
                    │  │             │  │             │      │
                    │  │ • Log Group │  │ • Health    │      │
                    │  │ • Metrics   │  │ • Queries   │      │
                    │  │ • Insights  │  │ • DNSSEC    │      │
                    │  │ • Analysis  │  │ • Resolver  │      │
                    │  └─────────────┘  └─────────────┘      │
                    │                                         │
                    │  ┌─────────────┐  ┌─────────────┐      │
                    │  │ Dashboards  │  │     SNS     │      │
                    │  │             │  │ Notifications│      │
                    │  │ • Overview  │  │             │      │
                    │  │ • Health    │  │ • Email     │      │
                    │  │ • DNSSEC    │  │ • Slack     │      │
                    │  │ • Queries   │  │ • Lambda    │      │
                    │  └─────────────┘  └─────────────┘      │
                    └─────────────────────────────────────────┘
```

## 주요 기능

### 🌐 DNS 관리

- **Public/Private Hosted Zones**: 퍼블릭 및 프라이빗 DNS 존 관리
- **DNS Records**: A, AAAA, CNAME, MX, NS, PTR, SRV, TXT, CAA 레코드 지원
- **Alias Records**: AWS 리소스에 대한 알리아스 레코드
- **라우팅 정책**: 가중치, 지연 시간, 장애 조치, 지리적 위치, 지리 근접성

### 🔒 보안 및 인증

- **DNSSEC**: 완전한 DNSSEC 지원 및 KMS 통합
- **Route53 Resolver Firewall**: DNS 방화벽 규칙
- **VPC 통합**: 프라이빗 호스팅 존 및 VPC 연결

### 🏥 헬스체크 및 모니터링

- **Health Checks**: HTTP/HTTPS, TCP, 계산된 헬스체크
- **CloudWatch 통합**: 메트릭, 알람, 대시보드
- **Query Logging**: DNS 쿼리 로깅 및 분석

### 🔧 Route53 Resolver

- **Resolver Endpoints**: 인바운드/아웃바운드 엔드포인트
- **Resolver Rules**: DNS 쿼리 포워딩 규칙
- **Cross-VPC DNS**: VPC 간 DNS 해석

### 📊 모니터링 및 분석

- **CloudWatch Insights**: 고급 로그 분석
- **Dashboard**: 종합적인 모니터링 대시보드
- **Alerting**: SNS 통합 알림

## 사용 예제

### 기본 Public Hosted Zone

```hcl
module "public_dns" {
  source = "./modules/route53"

  name        = "mycompany"
  environment = "prod"

  # Public hosted zone
  zones = {
    main = {
      domain_name  = "example.com"
      comment      = "Main company domain"
      private_zone = false
    }
  }

  # Basic DNS records
  records = {
    root = {
      zone_name = "main"
      name      = "example.com"
      type      = "A"
      ttl       = 300
      records   = ["1.2.3.4"]
    }
    www = {
      zone_name = "main"
      name      = "www.example.com"
      type      = "CNAME"
      ttl       = 300
      records   = ["example.com"]
    }
    mail = {
      zone_name = "main"
      name      = "example.com"
      type      = "MX"
      ttl       = 300
      records   = ["10 mail.example.com"]
    }
  }

  tags = {
    Project = "website"
    Owner   = "platform-team"
  }
}
```

### DNSSEC 활성화된 도메인

```hcl
module "secure_dns" {
  source = "./modules/route53"

  name        = "secure-app"
  environment = "prod"

  zones = {
    secure = {
      domain_name   = "secure.example.com"
      comment       = "Secure application domain"
      private_zone  = false
      enable_dnssec = true
    }
  }

  records = {
    app = {
      zone_name = "secure"
      name      = "app.secure.example.com"
      type      = "A"
      alias = {
        name                   = module.alb.dns_name
        zone_id                = module.alb.zone_id
        evaluate_target_health = true
      }
    }
  }

  # Health checks for the application
  health_checks = {
    app_health = {
      type          = "HTTPS"
      fqdn          = "app.secure.example.com"
      resource_path = "/health"
      port          = 443
      request_interval = 30
      failure_threshold = 3
      measure_latency = true
    }
  }

  # Enable monitoring
  create_cloudwatch_alarms = true
  alarm_actions = [aws_sns_topic.alerts.arn]

  tags = {
    Security    = "high"
    Compliance  = "required"
    Environment = "production"
  }
}
```

### Private Hosted Zone with VPC

```hcl
module "private_dns" {
  source = "./modules/route53"

  name        = "internal"
  environment = "prod"

  zones = {
    internal = {
      domain_name  = "internal.company.local"
      comment      = "Internal services domain"
      private_zone = true
      vpc_id       = module.vpc.vpc_id
      vpc_region   = "us-west-2"

      # Additional VPC associations
      additional_vpc_associations = [
        {
          vpc_id     = module.shared_vpc.vpc_id
          vpc_region = "us-west-2"
        }
      ]
    }
  }

  records = {
    database = {
      zone_name = "internal"
      name      = "db.internal.company.local"
      type      = "CNAME"
      ttl       = 300
      records   = [module.rds.db_instance_endpoint]
    }
    cache = {
      zone_name = "internal"
      name      = "redis.internal.company.local"
      type      = "CNAME"
      ttl       = 300
      records   = [module.elasticache.primary_endpoint]
    }
    api = {
      zone_name = "internal"
      name      = "api.internal.company.local"
      type      = "A"
      alias = {
        name                   = module.internal_alb.dns_name
        zone_id                = module.internal_alb.zone_id
        evaluate_target_health = true
      }
    }
  }

  tags = {
    Network = "private"
    Scope   = "internal"
  }
}
```

### Route53 Resolver with Hybrid DNS

```hcl
module "hybrid_dns" {
  source = "./modules/route53"

  name        = "hybrid"
  environment = "prod"

  # Resolver endpoints for hybrid connectivity
  resolver_endpoints = {
    inbound = {
      direction          = "INBOUND"
      security_group_ids = [module.vpc.default_security_group_id]
      subnet_ids         = module.vpc.private_subnet_ids
      name               = "corporate-inbound"
    }
    outbound = {
      direction          = "OUTBOUND"
      security_group_ids = [aws_security_group.resolver.id]
      subnet_ids         = module.vpc.private_subnet_ids
      name               = "corporate-outbound"
    }
  }

  # Resolver rules for forwarding
  resolver_rules = {
    corporate = {
      domain_name = "corp.company.com"
      rule_type   = "FORWARD"
      target_ips = [
        {
          ip   = "192.168.1.10"
          port = 53
        },
        {
          ip   = "192.168.1.11"
          port = 53
        }
      ]
    }
  }

  # Rule associations
  resolver_rule_associations = {
    main_vpc = {
      resolver_rule_id = "corp-rule"
      vpc_id           = module.vpc.vpc_id
    }
  }

  # Enable query logging
  create_query_logging = true
  query_log_retention_in_days = 30

  tags = {
    Connectivity = "hybrid"
    Purpose      = "dns-forwarding"
  }
}
```

### Multi-Region Failover Setup

```hcl
module "global_dns" {
  source = "./modules/route53"

  name        = "global-app"
  environment = "prod"

  zones = {
    global = {
      domain_name = "app.global.com"
      comment     = "Global application"
    }
  }

  # Health checks for each region
  health_checks = {
    us_east = {
      type          = "HTTPS"
      fqdn          = "us-east-1.app.global.com"
      resource_path = "/health"
      port          = 443
      regions       = ["us-east-1", "us-west-1", "eu-west-1"]
    }
    us_west = {
      type          = "HTTPS"
      fqdn          = "us-west-2.app.global.com"
      resource_path = "/health"
      port          = 443
      regions       = ["us-east-1", "us-west-1", "eu-west-1"]
    }
    eu_west = {
      type          = "HTTPS"
      fqdn          = "eu-west-1.app.global.com"
      resource_path = "/health"
      port          = 443
      regions       = ["us-east-1", "us-west-1", "eu-west-1"]
    }
  }

  records = {
    # Primary region (US East)
    primary = {
      zone_name = "global"
      name      = "app.global.com"
      type      = "A"
      set_identifier = "primary"
      failover_routing_policy = {
        type = "PRIMARY"
      }
      health_check_id = "us_east"
      alias = {
        name                   = "us-east-alb.elb.amazonaws.com"
        zone_id                = "Z35SXDOTRQ7X7K"
        evaluate_target_health = true
      }
    }
    # Secondary region (US West)
    secondary = {
      zone_name = "global"
      name      = "app.global.com"
      type      = "A"
      set_identifier = "secondary"
      failover_routing_policy = {
        type = "SECONDARY"
      }
      health_check_id = "us_west"
      alias = {
        name                   = "us-west-alb.elb.amazonaws.com"
        zone_id                = "Z1M58G0SJ5KRP"
        evaluate_target_health = true
      }
    }
    # Geolocation routing for Europe
    europe = {
      zone_name = "global"
      name      = "app.global.com"
      type      = "A"
      set_identifier = "europe"
      geolocation_routing_policy = {
        continent = "EU"
      }
      health_check_id = "eu_west"
      alias = {
        name                   = "eu-west-alb.elb.amazonaws.com"
        zone_id                = "Z32O12XQLNTSW2"
        evaluate_target_health = true
      }
    }
  }

  # Enable comprehensive monitoring
  create_cloudwatch_alarms = true
  create_query_logging     = true

  alarm_actions = [aws_sns_topic.global_alerts.arn]

  tags = {
    Scope        = "global"
    HighAvail    = "true"
    MultiRegion  = "true"
  }
}
```

### Certificate Validation with Route53

```hcl
# ACM Certificate
resource "aws_acm_certificate" "main" {
  domain_name       = "example.com"
  validation_method = "DNS"

  subject_alternative_names = [
    "*.example.com",
    "api.example.com",
    "www.example.com"
  ]

  lifecycle {
    create_before_destroy = true
  }
}

module "dns_with_ssl" {
  source = "./modules/route53"

  name        = "ssl-app"
  environment = "prod"

  zones = {
    main = {
      domain_name = "example.com"
    }
  }

  # Certificate validation
  certificate_validations = {
    main_cert = {
      certificate_arn = aws_acm_certificate.main.arn
    }
  }

  # Application records
  records = {
    root = {
      zone_name = "main"
      name      = "example.com"
      type      = "A"
      alias = {
        name                   = module.cloudfront.domain_name
        zone_id                = "Z2FDTNDATAQYW2"
        evaluate_target_health = false
      }
    }
    api = {
      zone_name = "main"
      name      = "api.example.com"
      type      = "A"
      alias = {
        name                   = module.api_gateway.domain_name
        zone_id                = module.api_gateway.hosted_zone_id
        evaluate_target_health = true
      }
    }
  }

  tags = {
    SSL = "enabled"
    CDN = "cloudfront"
  }
}
```

## 변수 설명

### 필수 변수

| 변수          | 타입     | 설명                      |
| ------------- | -------- | ------------------------- |
| `name`        | `string` | Route53 리소스 이름       |
| `environment` | `string` | 환경 (dev, staging, prod) |

### 선택적 변수

#### 호스팅 존 설정

| 변수                  | 타입          | 기본값  | 설명                   |
| --------------------- | ------------- | ------- | ---------------------- |
| `zones`               | `map(object)` | `{}`    | 생성할 호스팅 존 맵    |
| `zones.domain_name`   | `string`      | -       | 도메인 이름            |
| `zones.private_zone`  | `bool`        | `false` | 프라이빗 존 여부       |
| `zones.vpc_id`        | `string`      | `null`  | VPC ID (프라이빗 존용) |
| `zones.enable_dnssec` | `bool`        | `false` | DNSSEC 활성화          |

#### DNS 레코드 설정

| 변수                | 타입          | 기본값 | 설명                 |
| ------------------- | ------------- | ------ | -------------------- |
| `records`           | `map(object)` | `{}`   | 생성할 DNS 레코드 맵 |
| `records.zone_name` | `string`      | -      | 호스팅 존 이름       |
| `records.name`      | `string`      | -      | 레코드 이름          |
| `records.type`      | `string`      | -      | 레코드 타입          |
| `records.ttl`       | `number`      | `300`  | TTL 값               |
| `default_ttl`       | `number`      | `300`  | 기본 TTL 값          |

#### 헬스체크 설정

| 변수                              | 타입          | 기본값 | 설명             |
| --------------------------------- | ------------- | ------ | ---------------- |
| `health_checks`                   | `map(object)` | `{}`   | 헬스체크 설정 맵 |
| `health_checks.type`              | `string`      | -      | 헬스체크 타입    |
| `health_checks.fqdn`              | `string`      | `null` | 대상 FQDN        |
| `health_checks.port`              | `number`      | `null` | 포트 번호        |
| `health_checks.failure_threshold` | `number`      | `3`    | 실패 임계값      |

#### Route53 Resolver 설정

| 변수                         | 타입          | 기본값 | 설명                |
| ---------------------------- | ------------- | ------ | ------------------- |
| `resolver_endpoints`         | `map(object)` | `{}`   | Resolver 엔드포인트 |
| `resolver_rules`             | `map(object)` | `{}`   | Resolver 규칙       |
| `resolver_rule_associations` | `map(object)` | `{}`   | 규칙 연결           |

#### 모니터링 설정

| 변수                          | 타입           | 기본값  | 설명                 |
| ----------------------------- | -------------- | ------- | -------------------- |
| `create_cloudwatch_alarms`    | `bool`         | `false` | CloudWatch 알람 생성 |
| `create_query_logging`        | `bool`         | `false` | 쿼리 로깅 활성화     |
| `query_log_retention_in_days` | `number`       | `7`     | 로그 보존 기간       |
| `alarm_actions`               | `list(string)` | `[]`    | 알람 액션 목록       |

## 출력 값

### 주요 출력

| 출력                       | 설명                     |
| -------------------------- | ------------------------ |
| `hosted_zones`             | 호스팅 존 정보 맵        |
| `hosted_zone_ids`          | 호스팅 존 ID 맵          |
| `hosted_zone_name_servers` | 네임 서버 목록           |
| `dns_records`              | DNS 레코드 정보          |
| `health_checks`            | 헬스체크 정보            |
| `resolver_endpoints`       | Resolver 엔드포인트 정보 |

### 모니터링 출력

| 출력                    | 설명                 |
| ----------------------- | -------------------- |
| `cloudwatch_alarms`     | CloudWatch 알람 정보 |
| `cloudwatch_dashboards` | 대시보드 정보        |
| `query_log_groups`      | 쿼리 로그 그룹       |
| `sns_topics`            | SNS 토픽 정보        |

## DNS 레코드 타입별 예제

### A/AAAA 레코드

```hcl
records = {
  ipv4 = {
    zone_name = "main"
    name      = "server.example.com"
    type      = "A"
    ttl       = 300
    records   = ["1.2.3.4", "5.6.7.8"]
  }
  ipv6 = {
    zone_name = "main"
    name      = "server.example.com"
    type      = "AAAA"
    ttl       = 300
    records   = ["2001:db8::1", "2001:db8::2"]
  }
}
```

### CNAME 레코드

```hcl
records = {
  www = {
    zone_name = "main"
    name      = "www.example.com"
    type      = "CNAME"
    ttl       = 300
    records   = ["example.com"]
  }
}
```

### MX 레코드

```hcl
records = {
  mail = {
    zone_name = "main"
    name      = "example.com"
    type      = "MX"
    ttl       = 300
    records   = [
      "10 mail1.example.com",
      "20 mail2.example.com"
    ]
  }
}
```

### TXT 레코드 (SPF, DKIM, DMARC)

```hcl
records = {
  spf = {
    zone_name = "main"
    name      = "example.com"
    type      = "TXT"
    ttl       = 300
    records   = ["v=spf1 include:_spf.google.com ~all"]
  }
  dkim = {
    zone_name = "main"
    name      = "google._domainkey.example.com"
    type      = "TXT"
    ttl       = 300
    records   = ["v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA..."]
  }
  dmarc = {
    zone_name = "main"
    name      = "_dmarc.example.com"
    type      = "TXT"
    ttl       = 300
    records   = ["v=DMARC1; p=quarantine; rua=mailto:dmarc@example.com"]
  }
}
```

### SRV 레코드

```hcl
records = {
  sip = {
    zone_name = "main"
    name      = "_sip._tcp.example.com"
    type      = "SRV"
    ttl       = 300
    records   = ["10 60 5060 sipserver.example.com"]
  }
}
```

### CAA 레코드

```hcl
records = {
  caa = {
    zone_name = "main"
    name      = "example.com"
    type      = "CAA"
    ttl       = 300
    records   = [
      "0 issue \"letsencrypt.org\"",
      "0 issuewild \"letsencrypt.org\"",
      "0 iodef \"mailto:security@example.com\""
    ]
  }
}
```

### Alias 레코드 예제

#### ALB Alias

```hcl
records = {
  app = {
    zone_name = "main"
    name      = "app.example.com"
    type      = "A"
    alias = {
      name                   = module.alb.dns_name
      zone_id                = module.alb.zone_id
      evaluate_target_health = true
    }
  }
}
```

#### CloudFront Alias

```hcl
records = {
  cdn = {
    zone_name = "main"
    name      = "cdn.example.com"
    type      = "A"
    alias = {
      name                   = module.cloudfront.domain_name
      zone_id                = "Z2FDTNDATAQYW2"
      evaluate_target_health = false
    }
  }
}
```

#### S3 Website Alias

```hcl
records = {
  static = {
    zone_name = "main"
    name      = "static.example.com"
    type      = "A"
    alias = {
      name                   = module.s3_website.website_endpoint
      zone_id                = module.s3_website.hosted_zone_id
      evaluate_target_health = false
    }
  }
}
```

## 라우팅 정책 예제

### 가중치 기반 라우팅

```hcl
records = {
  app_v1 = {
    zone_name = "main"
    name      = "app.example.com"
    type      = "A"
    set_identifier = "version-1"
    weighted_routing_policy = {
      weight = 90
    }
    records = ["1.2.3.4"]
  }
  app_v2 = {
    zone_name = "main"
    name      = "app.example.com"
    type      = "A"
    set_identifier = "version-2"
    weighted_routing_policy = {
      weight = 10
    }
    records = ["5.6.7.8"]
  }
}
```

### 지연 시간 기반 라우팅

```hcl
records = {
  us_east = {
    zone_name = "main"
    name      = "api.example.com"
    type      = "A"
    set_identifier = "us-east-1"
    latency_routing_policy = {
      region = "us-east-1"
    }
    alias = {
      name                   = "us-east-alb.elb.amazonaws.com"
      zone_id                = "Z35SXDOTRQ7X7K"
      evaluate_target_health = true
    }
  }
  us_west = {
    zone_name = "main"
    name      = "api.example.com"
    type      = "A"
    set_identifier = "us-west-2"
    latency_routing_policy = {
      region = "us-west-2"
    }
    alias = {
      name                   = "us-west-alb.elb.amazonaws.com"
      zone_id                = "Z1M58G0SJ5KRP"
      evaluate_target_health = true
    }
  }
}
```

### 지리적 위치 라우팅

```hcl
records = {
  asia = {
    zone_name = "main"
    name      = "app.example.com"
    type      = "A"
    set_identifier = "asia"
    geolocation_routing_policy = {
      continent = "AS"
    }
    records = ["1.2.3.4"]
  }
  europe = {
    zone_name = "main"
    name      = "app.example.com"
    type      = "A"
    set_identifier = "europe"
    geolocation_routing_policy = {
      continent = "EU"
    }
    records = ["5.6.7.8"]
  }
  korea = {
    zone_name = "main"
    name      = "app.example.com"
    type      = "A"
    set_identifier = "korea"
    geolocation_routing_policy = {
      country = "KR"
    }
    records = ["9.10.11.12"]
  }
}
```

## 헬스체크 유형별 예제

### HTTP/HTTPS 헬스체크

```hcl
health_checks = {
  web_app = {
    type          = "HTTPS"
    fqdn          = "app.example.com"
    resource_path = "/health"
    port          = 443
    request_interval = 30
    failure_threshold = 3
    measure_latency = true
    enable_sni = true
    regions = ["us-east-1", "us-west-1", "eu-west-1"]
  }
}
```

### TCP 헬스체크

```hcl
health_checks = {
  database = {
    type          = "TCP"
    ip_address    = "10.0.1.100"
    port          = 3306
    request_interval = 30
    failure_threshold = 3
  }
}
```

### 문자열 매칭 헬스체크

```hcl
health_checks = {
  api_check = {
    type          = "HTTPS_STR_MATCH"
    fqdn          = "api.example.com"
    resource_path = "/status"
    port          = 443
    search_string = "\"status\":\"ok\""
    request_interval = 30
    failure_threshold = 3
  }
}
```

### 계산된 헬스체크

```hcl
health_checks = {
  app_overall = {
    type                   = "CALCULATED"
    child_health_checks    = ["web_app", "database", "cache"]
    child_health_threshold = 2
    reference_name         = "app-overall-health"
  }
}
```

### CloudWatch 메트릭 헬스체크

```hcl
health_checks = {
  custom_metric = {
    type                    = "CLOUDWATCH_METRIC"
    cloudwatch_alarm_region = "us-east-1"
    cloudwatch_alarm_name   = "application-error-rate"
    insufficient_data_health_status = "Success"
    reference_name          = "custom-app-health"
  }
}
```

## DNSSEC 설정

### 기본 DNSSEC 활성화

```hcl
zones = {
  secure_domain = {
    domain_name   = "secure.example.com"
    enable_dnssec = true
  }
}
```

### 커스텀 KMS 키를 사용한 DNSSEC

```hcl
resource "aws_kms_key" "dnssec" {
  description = "DNSSEC signing key"
  key_usage   = "SIGN_VERIFY"
  key_spec    = "ECC_NIST_P256"
}

dnssec_key_signing_keys = {
  main = {
    hosted_zone_id             = "Z123456789"
    key_management_service_arn = aws_kms_key.dnssec.arn
    name                       = "secure-example-ksk"
    status                     = "ACTIVE"
  }
}
```

## Route53 Resolver 설정

### 하이브리드 DNS 구성

```hcl
# 인바운드 엔드포인트 (온프레미스 → AWS)
resolver_endpoints = {
  inbound = {
    direction          = "INBOUND"
    security_group_ids = [aws_security_group.resolver.id]
    subnet_ids         = [subnet-12345, subnet-67890]
    ip_addresses = [
      {
        subnet_id = "subnet-12345"
        ip        = "10.0.1.100"
      },
      {
        subnet_id = "subnet-67890"
        ip        = "10.0.2.100"
      }
    ]
  }
}

# 아웃바운드 엔드포인트 (AWS → 온프레미스)
resolver_endpoints = {
  outbound = {
    direction          = "OUTBOUND"
    security_group_ids = [aws_security_group.resolver.id]
    subnet_ids         = [subnet-12345, subnet-67890]
  }
}

# 포워딩 규칙
resolver_rules = {
  corporate = {
    domain_name = "corp.company.com"
    rule_type   = "FORWARD"
    target_ips = [
      {
        ip   = "192.168.1.10"
        port = 53
      },
      {
        ip   = "192.168.1.11"
        port = 53
      }
    ]
  }
}
```

## 모니터링 및 알람

### CloudWatch 알람 설정

```hcl
create_cloudwatch_alarms = true
alarm_actions = [aws_sns_topic.dns_alerts.arn]

# 커스텀 헬스체크 알람
health_check_alarm_configs = {
  critical_app = {
    health_check_id = "web_app"
    alarm_name      = "critical-app-health-alarm"
    threshold       = 1
    comparison_operator = "LessThanThreshold"
  }
}
```

### 쿼리 로깅 및 분석

```hcl
create_query_logging = true
query_log_retention_in_days = 30
query_log_kms_key_id = aws_kms_key.logs.arn
```

## 비용 최적화

### 환경별 설정

```hcl
# 개발 환경
monitoring_interval = var.environment == "dev" ? 300 : 60
create_cloudwatch_alarms = var.environment != "dev"
query_log_retention_in_days = var.environment == "prod" ? 30 : 7

# 헬스체크 최적화
health_checks = var.environment == "prod" ? {
  # 프로덕션 헬스체크
} : {}
```

### 리소스 공유

```hcl
# Resolver 규칙 공유
resolver_rules = {
  shared_rule = {
    domain_name = "shared.company.com"
    rule_type   = "FORWARD"
    # RAM으로 다른 계정과 공유
  }
}
```

## 보안 모범 사례

### 1. DNSSEC 활성화

```hcl
zones = {
  main = {
    domain_name   = "example.com"
    enable_dnssec = true
  }
}
```

### 2. 프라이빗 존 사용

```hcl
zones = {
  internal = {
    domain_name  = "internal.company.local"
    private_zone = true
    vpc_id       = module.vpc.vpc_id
  }
}
```

### 3. Route53 Resolver Firewall

```hcl
# 악성 도메인 차단
resolver_endpoints = {
  inbound = {
    direction = "INBOUND"
    # 방화벽 규칙이 자동으로 생성됨
  }
}
```

### 4. 암호화

```hcl
# 로그 암호화
query_log_kms_key_id = aws_kms_key.logs.arn

# DNSSEC 키 암호화
dnssec_key_signing_keys = {
  main = {
    key_management_service_arn = aws_kms_key.dnssec.arn
  }
}
```

## 문제 해결

### 1. DNS 해석 문제

```bash
# Route53 쿼리 로그 확인
aws logs filter-log-events \
  --log-group-name "/aws/route53/myapp-prod/query-logs" \
  --filter-pattern "ERROR"

# 헬스체크 상태 확인
aws route53 get-health-check --health-check-id 12345
```

### 2. DNSSEC 문제

```bash
# DNSSEC 상태 확인
dig +dnssec example.com

# KSK 상태 확인
aws route53 get-dnssec --hosted-zone-id Z123456789
```

### 3. Resolver 문제

```bash
# Resolver 엔드포인트 상태 확인
aws route53resolver list-resolver-endpoints

# Resolver 규칙 확인
aws route53resolver list-resolver-rules
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
