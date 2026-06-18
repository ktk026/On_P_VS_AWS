# AWS / EKS Environment

이 디렉토리는 AWS EKS 환경 구성과 운영 문서를 관리한다.

## 목표

- EKS 기반 Kubernetes 클러스터 구성
- 온프레미스와 동일한 Shoply 이미지 배포
- HPA + Karpenter 기반 자동 확장 반응 관찰
- 온프레미스 고정 노드 환경과 동일 부하 조건으로 비교

## 주요 구성

| 영역 | 내용 |
|---|---|
| Kubernetes | AWS EKS |
| 이미지 레지스트리 | GHCR |
| DB | RDS PostgreSQL 또는 실험용 PostgreSQL |
| Cache | Redis |
| Autoscaling | HPA, Karpenter |
| Monitoring | Prometheus/Grafana 연동 |

## 배포 기준

Shoply 애플리케이션 이미지는 GHCR 태그를 사용한다.

```text
ghcr.io/ktk026/shoply-<service>:<tag>
```

온프레미스와 EKS 비교 실험에서는 `latest` 대신 커밋 SHA 또는 실험용 고정 태그를 사용한다.

## 관련 문서

- [../msa_shoply/k8s/README.md](../msa_shoply/k8s/README.md)
- [../docs/experiment-plan.md](../docs/experiment-plan.md)
- [../load-test/k6/README.md](../load-test/k6/README.md)
