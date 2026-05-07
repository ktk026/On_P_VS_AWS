# 될랑가...? (it's workinggg..?)
온프레미스 서버를 위한 클라우드 확장 서비스

## 프로젝트 소개
온프레미스 환경에서 운영되는 서비스에서 트래픽 폭주 발생 시 , AWS 클라우드 자원으로 자동 확장해 트래픽을 분산시키는 하이브리드 클라우드 기반 자동 확장 플랫폼

## 주요기능
- Route53 기반 트래픽 분산
- Terraform 기반 AWS 인프라 자동 생성
- GitHub Actions 기반 CI/CD 자동화
- CloudWatch 기반 모니터링
- Lambda 기반 자동 확장 및 회수
- Grafana 기반 실시간 대시보드


## 기술스택
- AWS
- Terraform
- GitHub Actions
- Docker
- Route53
- Lambda
- CloudWatch
- Grafana
- Ansible

# CI / CD 파이프라인
GitHub Actions 기반 CI/CD 파이프라인을 구성

- main 브랜치 push 시 자동 실행
- terraform init 자동 수행
- terraform fmt 코드 포맷 검사
- terraform validate 문법 검사
- terraform plan 실행 예정 인프라 확인

향후:
- AWS Credentials 연동
- terraform apply 자동화
- Docker ECR Push 자동화
- Lambda 기반 자동 확장 연동 예정
