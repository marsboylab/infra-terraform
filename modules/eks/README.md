# EKS Module

이 모듈은 AWS EKS (Elastic Kubernetes Service) 클러스터와 관련된 모든 리소스를 생성합니다.

## 주요 기능

- **EKS 클러스터**: 완전 관리형 Kubernetes 클러스터
- **관리형 노드 그룹**: 자동 스케일링과 업데이트를 지원하는 워커 노드
- **IRSA (IAM Roles for Service Accounts)**: 서비스 어카운트용 IAM 역할
- **보안 그룹**: 클러스터와 노드 간의 네트워크 보안
- **EKS 애드온**: CoreDNS, VPC CNI, kube-proxy, EBS CSI 드라이버
- **CloudWatch 로깅**: 클러스터 로그 수집 및 저장

## 아키텍처

```
┌─────────────────────────────────────────────────────────────────┐
│                        EKS Cluster                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────┐    ┌─────────────────┐    ┌──────────────┐ │
│  │   Control Plane │    │   Node Groups   │    │   Add-ons    │ │
│  │                 │    │                 │    │              │ │
│  │ - API Server    │    │ - Main Nodes    │    │ - CoreDNS    │ │
│  │ - etcd          │    │ - Custom Nodes  │    │ - VPC CNI    │ │
│  │ - Scheduler     │    │ - Auto Scaling  │    │ - kube-proxy │ │
│  │ - Controller    │    │                 │    │ - EBS CSI    │ │
│  └─────────────────┘    └─────────────────┘    └──────────────┘ │
│                                                                 │
├─────────────────────────────────────────────────────────────────┤
│                        IRSA & IAM                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────────┐    ┌─────────────────┐    ┌──────────────┐ │
│  │ Cluster Roles   │    │   Node Roles    │    │ Service Roles│ │
│  │                 │    │                 │    │              │ │
│  │ - EKS Service   │    │ - Worker Nodes  │    │ - Load Bal.  │ │
│  │ - VPC Resources │    │ - CNI Plugin    │    │ - External   │ │
│  │                 │    │ - ECR Access    │    │   DNS        │ │
│  │                 │    │                 │    │ - Autoscaler │ │
│  └─────────────────┘    └─────────────────┘    └──────────────┘ │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

## 사용 예제

### 기본 사용법

```hcl
module "eks" {
  source = "./modules/eks"

  cluster_name = "my-eks-cluster"
  environment  = "dev"
  region       = "ap-northeast-2"

  vpc_id     = "vpc-xxxxxxxxx"
  subnet_ids = ["subnet-xxxxxxxxx", "subnet-yyyyyyyyy"]

  tags = {
    Environment = "dev"
    Project     = "my-project"
  }
}
```

### 고급 설정

```hcl
module "eks" {
  source = "./modules/eks"

  cluster_name    = "production-eks"
  cluster_version = "1.28"
  environment     = "prod"
  region          = "ap-northeast-2"

  vpc_id                      = "vpc-xxxxxxxxx"
  subnet_ids                  = ["subnet-xxxxxxxxx", "subnet-yyyyyyyyy"]
  control_plane_subnet_ids    = ["subnet-aaaaaaa", "subnet-bbbbbbb"]

  # 엔드포인트 접근 설정
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = false

  # 추가 노드 그룹 정의
  node_groups = {
    spot = {
      instance_types = ["m5.large", "m5.xlarge"]
      ami_type       = "AL2_x86_64"
      capacity_type  = "SPOT"
      disk_size      = 30

      scaling_config = {
        desired_size = 2
        max_size     = 10
        min_size     = 0
      }

      update_config = {
        max_unavailable_percentage = 50
      }

      labels = {
        WorkerType = "spot"
      }

      taints = [
        {
          key    = "spot"
          value  = "true"
          effect = "NO_SCHEDULE"
        }
      ]

      tags = {
        NodeType = "spot"
      }
    }
  }

  # IRSA 역할 설정
  irsa_roles = {
    my_app = {
      namespace                    = "default"
      service_account_name        = "my-app-sa"
      role_policy_arns           = ["arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"]
      inline_policy_statements   = [
        {
          effect = "Allow"
          actions = [
            "ssm:GetParameter",
            "ssm:GetParameters"
          ]
          resources = ["arn:aws:ssm:*:*:parameter/my-app/*"]
        }
      ]
    }
  }

  # 로깅 설정
  cluster_enabled_log_types = ["api", "audit", "authenticator"]
  cloudwatch_log_group_retention_in_days = 30

  # 애드온 설정
  cluster_addons = {
    vpc-cni = {
      version = "v1.13.4-eksbuild.1"
      resolve_conflicts = "OVERWRITE"
      service_account_role_arn = ""
    }
  }

  tags = {
    Environment = "prod"
    Project     = "my-project"
    Owner       = "platform-team"
  }
}
```

### 완전한 환경 설정

```hcl
# VPC 모듈 (별도 정의 필요)
module "vpc" {
  source = "./modules/vpc"

  environment = "dev"
  region      = "ap-northeast-2"

  # VPC 설정...
}

# EKS 모듈
module "eks" {
  source = "./modules/eks"

  cluster_name = "my-cluster"
  environment  = "dev"
  region       = "ap-northeast-2"

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  # 기본 노드 그룹 설정
  default_node_group = {
    instance_types = ["t3.medium"]
    ami_type       = "AL2_x86_64"
    capacity_type  = "ON_DEMAND"
    disk_size      = 20

    scaling_config = {
      desired_size = 3
      max_size     = 10
      min_size     = 1
    }

    update_config = {
      max_unavailable_percentage = 25
    }

    labels = {
      Environment = "dev"
    }

    taints = []
  }

  # 추가 보안 그룹 규칙
  cluster_security_group_additional_rules = {
    ingress_workstation_https = {
      description = "Allow workstation to communicate with the cluster API Server"
      protocol    = "tcp"
      from_port   = 443
      to_port     = 443
      type        = "ingress"
      cidr_blocks = ["10.0.0.0/8"]
      source_security_group_id = ""
    }
  }

  tags = {
    Environment = "dev"
    Project     = "my-project"
  }
}

# kubectl 설정을 위한 출력
output "cluster_config" {
  value = module.eks.cluster_config
}
```

## 입력 변수

| 변수                              | 타입           | 기본값   | 설명                          |
| --------------------------------- | -------------- | -------- | ----------------------------- |
| `cluster_name`                    | `string`       | -        | EKS 클러스터 이름             |
| `cluster_version`                 | `string`       | `"1.28"` | Kubernetes 버전               |
| `environment`                     | `string`       | -        | 환경 이름 (dev, stg, prod)    |
| `region`                          | `string`       | -        | AWS 리전                      |
| `vpc_id`                          | `string`       | -        | VPC ID                        |
| `subnet_ids`                      | `list(string)` | -        | 서브넷 ID 목록                |
| `control_plane_subnet_ids`        | `list(string)` | `[]`     | 컨트롤 플레인 서브넷 ID 목록  |
| `cluster_endpoint_private_access` | `bool`         | `true`   | 프라이빗 엔드포인트 접근 허용 |
| `cluster_endpoint_public_access`  | `bool`         | `true`   | 퍼블릭 엔드포인트 접근 허용   |
| `node_groups`                     | `map(object)`  | `{}`     | 추가 노드 그룹 설정           |
| `irsa_roles`                      | `map(object)`  | `{}`     | IRSA 역할 설정                |
| `enable_irsa`                     | `bool`         | `true`   | IRSA 활성화 여부              |
| `tags`                            | `map(string)`  | `{}`     | 리소스 태그                   |

## 출력 값

| 출력                                 | 설명                         |
| ------------------------------------ | ---------------------------- |
| `cluster_name`                       | EKS 클러스터 이름            |
| `cluster_endpoint`                   | 클러스터 API 서버 엔드포인트 |
| `cluster_certificate_authority_data` | 클러스터 인증서 데이터       |
| `oidc_provider_arn`                  | OIDC 공급자 ARN              |
| `node_groups`                        | 노드 그룹 정보               |
| `cluster_config`                     | kubectl 설정 정보            |
| `common_irsa_role_arns`              | 공통 IRSA 역할 ARN 목록      |

## 사전 요구사항

1. **VPC 모듈**: EKS 클러스터가 배포될 VPC
2. **적절한 IAM 권한**: Terraform 실행을 위한 IAM 권한
3. **AWS CLI 설정**: kubectl 설정을 위한 AWS CLI

## 클러스터 접근 설정

EKS 클러스터에 접근하려면 다음 명령을 실행합니다:

```bash
# AWS CLI를 사용하여 kubectl 설정 업데이트
aws eks update-kubeconfig --region ap-northeast-2 --name my-eks-cluster

# 클러스터 상태 확인
kubectl get nodes
kubectl get pods --all-namespaces
```

## 포함된 IRSA 역할

이 모듈은 다음과 같은 공통 IRSA 역할을 자동으로 생성합니다:

- **aws-load-balancer-controller**: AWS Load Balancer Controller
- **external-dns**: External DNS
- **cluster-autoscaler**: Cluster Autoscaler
- **external-secrets**: External Secrets Operator

## 모니터링 및 로깅

- **CloudWatch 로그**: 클러스터 로그는 CloudWatch에 저장됩니다
- **Container Insights**: 노드에 CloudWatch 에이전트가 설치됩니다
- **메트릭 수집**: CPU, 메모리, 네트워크 메트릭을 수집합니다

## 보안 고려사항

1. **네트워크 보안**: 보안 그룹으로 네트워크 트래픽을 제어합니다
2. **IAM 역할**: 최소 권한 원칙을 적용합니다
3. **암호화**: EBS 볼륨과 통신이 암호화됩니다
4. **접근 제어**: RBAC으로 클러스터 접근을 제어합니다

## 업그레이드 및 유지보수

1. **클러스터 업그레이드**: `cluster_version` 변수로 버전을 관리합니다
2. **노드 그룹 업데이트**: 롤링 업데이트를 지원합니다
3. **애드온 업데이트**: 애드온 버전을 개별적으로 관리합니다

## 문제 해결

### 일반적인 문제

1. **노드가 클러스터에 연결되지 않음**

   - 보안 그룹 규칙 확인
   - IAM 역할 및 정책 확인
   - 서브넷 라우팅 확인

2. **Pod가 시작되지 않음**

   - 노드 용량 확인
   - 이미지 풀 권한 확인
   - 리소스 제한 확인

3. **외부 서비스 접근 불가**
   - 로드 밸런서 설정 확인
   - 보안 그룹 규칙 확인
   - IRSA 역할 확인

### 로그 확인

```bash
# 클러스터 로그 확인
aws logs describe-log-groups --log-group-name-prefix /aws/eks/my-cluster

# 노드 로그 확인
kubectl logs -n kube-system -l k8s-app=aws-node

# 애드온 상태 확인
kubectl get addon -A
```

## 참고 자료

- [AWS EKS 사용 설명서](https://docs.aws.amazon.com/eks/)
- [Kubernetes 문서](https://kubernetes.io/docs/)
- [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/)
- [External DNS](https://github.com/kubernetes-sigs/external-dns)
- [Cluster Autoscaler](https://github.com/kubernetes/autoscaler/tree/master/cluster-autoscaler)
