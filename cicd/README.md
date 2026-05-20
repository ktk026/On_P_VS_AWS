# CI/CD 구성

## 목표

온프레미스(on-pre) 환경과 AWS 환경의 배포 자동화 구조를 설계합니다.

현재 CI/CD 도구는 확정하지 않았으며, Jenkins와 GitHub Actions 중 프로젝트 상황에 맞는 방식을 검토합니다.

---

## 주요 작업

- 애플리케이션 빌드 자동화
- Docker 이미지 생성 자동화
- 온프레미스 환경 배포 자동화
- AWS EKS 환경 배포 자동화
- 브랜치 기반 배포 흐름 정리
- 배포 실패 시 롤백 방식 검토

---

## 검토 예정 도구

- Jenkins
- GitHub Actions
- Docker Registry
- AWS ECR
- kubectl
- Helm

---

## 디렉토리 역할

이 디렉토리는 CI/CD 관련 설정 파일, 파이프라인 스크립트, 배포 자동화 문서를 관리합니다.

도구가 확정되기 전까지는 구체적인 Jenkinsfile이나 workflow 파일을 생성하지 않습니다.

---

## 작업 브랜치



## 서비스별 포트 및 ECR 저장소 규칙

GitHub Actions, Docker Build, AWS ECR, Kubernetes 배포 시
서비스명을 통일하기 위해 아래 규칙을 사용한다.

| Service | Port | ECR Repository |
|---|---:|---|
| frontend | 3000 | shoply-frontend |
| gateway | 4000 | shoply-gateway |
| product | 4001 | shoply-product |
| inventory | 4002 | shoply-inventory |
| order | 4003 | shoply-order |
| payment | 4004 | shoply-payment |
| user | 4005 | shoply-user |

GitHub Actions, Docker Build, AWS ECR, Kubernetes 배포 시
서비스명을 통일하기 위해 아래 규칙을 사용한다.
