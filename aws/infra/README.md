# AWS EKS 인프라 구축기 — Shoply Benchmark Project

> 온프레미스(EC2+KVM) vs AWS EKS, 같은 쇼핑몰 앱을 두 환경에 띄우고 "탄력성"이라는 단 하나의 변수로 비교한 팀 프로젝트에서, AWS EKS 인프라 설계를 담당하며 진행한 과정을 정리했습니다.

---

## 1. 프로젝트에서 내가 맡은 부분

팀은 4명이 각자 온프레미스, EKS 인프라, 서비스 배포, CI/CD·부하테스트를 나눠 맡았고, 저는 그중 **AWS EKS 인프라 설계**를 담당했습니다. Terraform으로 VPC부터 EKS, 보안그룹, IAM, RDS, Redis까지 전 계층을 코드로 구성하는 것이 목표였습니다.

실험의 핵심 변수는 "노드 자동확장 유무" 하나였기 때문에, 온프레미스 워커 노드와 동일한 스펙(`c8i-flex.large`)으로 EKS 워커 노드를 고정하고, EKS Auto Mode 대신 Managed Node Group + Karpenter 조합을 직접 구성해서 이 변수 하나만 남도록 설계했습니다.

![Terraform으로 구성한 EKS 전체 아키텍처 다이어그램](경로/architecture-diagram.png)
*VPC → EKS 노드그룹 → RDS/Redis까지 이어지는 전체 구조도*

---

## 2. 이렇게 만들었습니다

### 2.1 네트워크 & 보안 계층
VPC와 퍼블릭 서브넷 2개(2a, 2c)로 네트워크를 구성하고, 역할별로 보안그룹을 5개로 나눠 최소 권한 원칙을 지켰습니다.

| 보안그룹 | 용도 |
|---|---|
| `app-eks-worker-sg` | 워커 노드 |
| `app-load-balancer-sg` | 80/443 인그레스 트래픽 허용 |
| `app-rds-sg` | RDS 접근, 워커 노드 SG만 허용 |
| `app-redis-sg` | Redis 접근, 워커 노드 SG만 허용 |
| `app-k6-sg` | 부하 테스트 서버 전용 |

📸 **코드 스크린샷 추천**: `security_groups.tf`에서 5개 SG와 각 `ingress`/`egress` 블록이 한 화면에 보이는 부분

IAM은 `infra_group`(VPC·EKS 프로비저닝), `k8s_group`(클러스터 운영), `cicd_group`(ECR push·배포) 세 그룹으로 나눠 관리했고, 그룹 정책은 아래처럼 정책 파일을 참조하면서 그룹 생성 이후에 적용되도록 의존성을 명시했습니다.

```hcl
resource "aws_iam_group_policy" "infra_policy" {
  name  = "infra_group"
  group = aws_iam_group.infra_group.name
  policy = file("${path.module}/infra_group.json")
  depends_on = [aws_iam_group.infra_group]
}

resource "aws_iam_group_policy" "k8s_policy" {
  name  = "k8s_group"
  group = aws_iam_group.k8s_group.name
  policy = file("${path.module}/k8s_group.json")
  depends_on = [aws_iam_group.k8s_group]
}

resource "aws_iam_group_policy" "cicd_policy" {
  name  = "cicd_group"
  group = aws_iam_group.cicd_group.name
  policy = file("${path.module}/cicd_group.json")
  depends_on = [aws_iam_group.cicd_group]
}
```

📸 **코드 스크린샷 추천**: 위 IAM 그룹 정책 코드가 실제 IDE에 열려 있는 화면 + AWS 콘솔의 IAM 그룹 3개 목록

### 2.2 컴퓨팅 계층 (EKS)
Launch Template을 Terraform으로 직접 관리해서, 온프레미스 워커 노드와 동일한 스펙(`c8i-flex.large`)으로 EKS 워커 노드 인스턴스 타입을 고정했습니다. api 노드그룹과 service 노드그룹으로 역할을 분리했습니다.

```hcl
resource "aws_launch_template" "eks_api_nodes_template" {
  name_prefix   = "eks-api-node-"
  image_id      = data.aws_ssm_parameter.eks_ubuntu_ami.value
  instance_type = "c8i-flex.large"
  key_name      = var.key_name

  vpc_security_group_ids = [
    aws_eks_cluster.eks.vpc_config[0].cluster_security_group_id,
    aws_security_group.eks_worker_sg.id
  ]

  user_data = base64encode(local.eks_node_user_data)

  tag_specifications {
    resource_type = "instance"
    tags          = { Name = "eks-api-node-instance" }
  }

  lifecycle {
    create_before_destroy = true
  }
}
```

- **AMI**: 하드코딩 대신 `data.aws_ssm_parameter.eks_ubuntu_ami`로 최신 Ubuntu EKS AMI를 동적으로 조회
- **보안그룹**: `cluster_security_group`과 `eks_worker_sg`를 이중으로 적용
- **무중단 교체**: `create_before_destroy = true`로 노드 교체 시 서비스 끊김 방지

📸 **코드 스크린샷 추천**: 위 Launch Template 코드 전체(2개 노드그룹 템플릿이 나란히 보이는 IDE 화면)

### 2.3 데이터 계층
RDS PostgreSQL 16을 관리형으로 구성해 온프레미스의 EC2 PostgreSQL 16과 엔진 버전을 맞췄습니다. Redis는 클러스터를 몇 번이고 다시 만들어야 하는 실험 환경 특성상, 재생성해도 연결이 끊기지 않도록 전용 ENI를 별도로 만들어 Private IP를 고정했습니다.

```hcl
resource "aws_network_interface" "redis_eni" {
  subnet_id       = aws_subnet.public_2a.id
  security_groups = [aws_security_group.app_redis_sg.id]
  private_ips     = ["10.0.1.50"]
}

resource "aws_instance" "redis" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "c8i-flex.large"

  network_interface {
    network_interface_id = aws_network_interface.redis_eni.id
    device_index          = 0
  }
}
```

📸 **코드 스크린샷 추천**: `aws_network_interface` + `aws_instance` 코드 화면, 그리고 EC2 콘솔에서 Redis 인스턴스에 고정된 Private IP가 보이는 화면

### 2.4 관찰성 (모니터링 연동)
EKS 쪽에는 별도로 Prometheus/Grafana를 두지 않고, 모든 노드에 DaemonSet(Node Exporter, cAdvisor, Promtail)만 배포해서 메트릭·로그를 노출하도록 했습니다. Taint/Toleration으로 Ops 노드와 Worker 노드를 분리해, 모니터링 에이전트가 실험 워크로드의 자원을 갉아먹지 않도록 신경 썼습니다.

```yaml
tolerations:
  - key: "node-role"
    operator: "Equal"
    value: "ops"
    effect: "NoSchedule"
```

📸 **코드 스크린샷 추천**: DaemonSet values.yaml의 `tolerations` 블록 + `kubectl get pods -o wide`로 Exporter가 모든 노드에 떠 있는 화면

### 2.5 이미지 저장소 (ECR)
7개 마이크로서비스(gateway, product, inventory, order, payment, user, frontend) 각각에 대해 ECR 리포지토리를 Terraform으로 생성하고 AES-256 암호화를 적용했습니다.

```hcl
resource "aws_ecr_repository" "services" {
  for_each             = toset(["gateway", "product", "inventory", "order", "payment", "user", "frontend"])
  name                 = "app-${each.key}"
  image_tag_mutability = "MUTABLE"

  encryption_configuration {
    encryption_type = "AES256"
  }
}
```

![ECR 레지스트리 — 7개 서비스 리포지토리 목록](경로/ecr-repositories.png)

---

## 3. 결과

같은 부하 조건에서 온프레미스는 노드가 꽉 차면 파드가 Pending으로 쌓이기만 했지만, EKS는 HPA가 Pod를 늘리고 Karpenter가 뒤따라 노드를 자동으로 붙이면서 서비스를 계속 유지했습니다. CPU 사용률이 최대 90.83%까지 올라가는 상황에서도 자원 부족으로 막히지 않았고, 이건 처음 설계할 때 목표했던 "탄력성 유무만 변수로 남긴다"는 방향이 제대로 작동했다는 걸 확인시켜준 결과였습니다.

![온프레미스 vs EKS 최종 비교 결과표](경로/final-comparison-result.png)
*트래픽 급증 시 온프레미스는 Pending 적체, EKS는 HPA+Karpenter로 자동 확장된 최종 비교 결과*

---

*Shoply Benchmark Project — AWS EKS 인프라 설계 파트 (Terraform IaC)*
