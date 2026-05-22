# CI/CD 구성

## 목표

온프레미스(on-pre) Kubernetes 환경과 AWS EKS 환경의 배포 자동화 구조를 설계한다.

본 프로젝트는 Jenkins와 GitHub Actions를 비교 검토한 뒤,
현재는 GitHub Actions 기반으로 CI/CD를 구성한다.

Docker 이미지는 GitHub Container Registry(GHCR)를 사용하여 관리하며,
온프레미스 Kubernetes와 AWS EKS가 동일한 이미지를 Pull하여 실행하는 구조를 목표로 한다.

---

## 주요 작업

- 애플리케이션 빌드 자동화
- Docker 이미지 생성 자동화
- GitHub Container Registry(GHCR) 이미지 Push 자동화
- 온프레미스 Kubernetes 환경 배포 자동화
- AWS EKS 환경 배포 자동화
- 브랜치 기반 CI/CD 흐름 정리
- 배포 실패 시 롤백 방식 검토

---

## 사용 및 검토 도구

- GitHub Actions
- Docker
- GitHub Container Registry (GHCR)
- Kubernetes
- AWS EKS
- kubectl
- Helm
- Jenkins
- AWS ECR

> Jenkins와 AWS ECR은 초기 검토 대상이었으나,
> 현재 프로젝트에서는 GitHub Actions와 GHCR을 우선 사용한다.

---

## 디렉토리 역할

이 디렉토리는 CI/CD 관련 설정 파일,
GitHub Actions workflow,
파이프라인 스크립트,
배포 자동화 문서를 관리한다.

현재는 GitHub Actions 기반의 Docker Build 및 GHCR Push 흐름을 우선 구성한다.

---

## 서비스별 포트 및 GHCR 이미지 규칙

GitHub Actions, Docker Build, GHCR, Kubernetes 배포 시
서비스명을 통일하기 위해 아래 규칙을 사용한다.

| Service | Port | GHCR Image |
|---|---:|---|
| frontend | 3000 | ghcr.io/ktk026/shoply-frontend |
| gateway | 4000 | ghcr.io/ktk026/shoply-gateway |
| product | 4001 | ghcr.io/ktk026/shoply-product |
| inventory | 4002 | ghcr.io/ktk026/shoply-inventory |
| order | 4003 | ghcr.io/ktk026/shoply-order |
| payment | 4004 | ghcr.io/ktk026/shoply-payment |
| user | 4005 | ghcr.io/ktk026/shoply-user |

---

## 브랜치 전략

본 프로젝트는 온프레미스 Kubernetes 환경과 AWS EKS 환경을 비교 실험하는 구조이므로,
작업 영역별 브랜치를 분리하여 관리한다.

### 기본 브랜치

- `main`: 최종 안정 버전
- `develop`: 통합 테스트 브랜치

### 작업 브랜치

- `on-pre`: 온프레미스 Kubernetes 관련 작업
- `aws`: AWS EKS 및 인프라 관련 작업
- `cicd`: GitHub Actions, Docker Build, GHCR Push, 배포 자동화 관련 작업

### 작업 흐름

```text
on-pre → develop
aws → develop
cicd → develop

develop → main
```

---

## CI/CD 흐름

본 프로젝트는 GitHub Actions를 사용하여 Docker 이미지를 빌드하고,
GitHub Container Registry(GHCR)에 이미지를 저장한다.

온프레미스 Kubernetes 환경과 AWS EKS 환경은
동일한 GHCR 이미지를 Pull하여 실행하는 구조를 사용한다.

```text
Code Push
→ GitHub Actions
→ Docker Build
→ Container 실행 테스트
→ Health Check
→ GHCR Push
→ Kubernetes 배포
   ├── on-pre Kubernetes
   └── AWS EKS
```

---

## 현재 활성화된 Workflow

현재는 `docker-build-test.yml` workflow를 우선 활성화한다.

해당 workflow는 Gateway 서비스를 기준으로 Docker 이미지가 정상적으로 빌드되고,
컨테이너 실행 및 Health Check가 가능한지 검증한 뒤 GHCR에 이미지를 Push한다.

### 현재 테스트 대상

| 항목 | 내용 |
|---|---|
| 대상 서비스 | gateway |
| Dockerfile 경로 | `app/shoply/gateway/Dockerfile` |
| 이미지 이름 | `ghcr.io/ktk026/shoply-gateway` |
| 테스트 태그 | `cicd-test` |
| 서비스 포트 | 4000 |
| Health Check | `/health` |

---

## GitHub Actions Workflow 구성 계획

서비스별 Docker 이미지 빌드 및 배포 관리를 위해
GitHub Actions workflow를 서비스 단위로 분리할 계획이다.

현재는 Gateway 서비스 기준으로 Docker Build,
컨테이너 실행 테스트,
Health Check,
GHCR Push 흐름을 먼저 검증한다.

이후 각 서비스의 Dockerfile 및 Kubernetes 배포 구조가 확정되면
workflow를 서비스 단위로 순차적으로 추가한다.

| Workflow 파일 | 대상 서비스 | GHCR Image | 상태 |
|---|---|---|---|
| docker-build-test.yml | gateway 테스트 | ghcr.io/ktk026/shoply-gateway | 활성화 |
| gateway.yml | gateway | ghcr.io/ktk026/shoply-gateway | 예정 |
| frontend.yml | frontend | ghcr.io/ktk026/shoply-frontend | 예정 |
| product.yml | product | ghcr.io/ktk026/shoply-product | 예정 |
| inventory.yml | inventory | ghcr.io/ktk026/shoply-inventory | 예정 |
| order.yml | order | ghcr.io/ktk026/shoply-order | 예정 |
| payment.yml | payment | ghcr.io/ktk026/shoply-payment | 예정 |
| user.yml | user | ghcr.io/ktk026/shoply-user | 예정 |

---

## AWS EKS 배포 시 이미지 사용 예시

AWS EKS에서는 Deployment YAML의 container image 항목에
GHCR 이미지를 지정하여 배포한다.

```yaml
containers:
  - name: gateway
    image: ghcr.io/ktk026/shoply-gateway:cicd-test
    ports:
      - containerPort: 4000
```

---

## 향후 작업

- GHCR 이미지 Public/Private 정책 결정
- Private 이미지 사용 시 Kubernetes `imagePullSecret` 구성
- 서비스별 Dockerfile 정리
- 서비스별 GitHub Actions workflow 추가
- Kubernetes Deployment / Service YAML 연동
- on-pre Kubernetes와 AWS EKS 배포 방식 비교
- 배포 실패 시 Rollback 방식 정리