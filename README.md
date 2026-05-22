# ON_P_VS_AWS

온프레미스 vs AWS 기반 하이브리드 클라우드 확장 플랫폼

## 프로젝트 소개

온프레미스 환경에서 운영되는 서비스를 Kubernetes 기반으로 구성하고, 트래픽 증가 상황에서 AWS EKS 환경과 비교하여 확장성, 운영성, 모니터링 차이를 분석하는 프로젝트입니다.

온프레미스 환경은 kubeadm 기반 Kubernetes 클러스터로 구성하고, AWS 환경은 EKS 기반 Kubernetes 클러스터로 구성합니다. 동일한 애플리케이션을 양쪽 환경에 배포하여 부하 테스트와 모니터링 결과를 비교합니다.

## 프로젝트 목표

- 온프레미스 Kubernetes 환경 구축
- AWS EKS 환경 구축
- 동일 애플리케이션의 양쪽 환경 배포
- 모니터링 및 부하 테스트 기반 비교
- CI/CD 자동화 구조 설계

## 프로젝트 구조

```text
ON_P_VS_AWS/
├─ app/          # 공통 애플리케이션 코드
├─ database/     # 공통 DB 스키마 및 초기 데이터
├─ load-test/    # 부하 테스트 스크립트
├─ on-pre/       # 온프레미스 환경 구성
├─ aws/          # AWS EKS 환경 구성
├─ cicd/         # CI/CD 관련 구성
└─ docs/         # 문서GHCR test
