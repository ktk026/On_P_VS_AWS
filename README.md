# ON_P_VS_AWS

온프레미스 Kubernetes와 AWS EKS에 동일한 Shoply 애플리케이션을 배포하고, 동일한 부하 조건에서 확장성, 장애 대응, 모니터링 차이를 비교하는 프로젝트다.

## 핵심 목표

- 동일한 애플리케이션 이미지를 온프레미스와 EKS에 배포
- k6 부하테스트로 주문/결제 흐름과 실제 사용자 흐름을 재현
- Prometheus/Grafana로 TPS, P95 latency, error rate, Pod/Node 상태를 비교
- 온프레미스의 고정 노드 한계와 EKS의 자동 확장 반응을 데이터로 설명
- GitHub Actions와 GHCR 기반 이미지 전달 구조 정리

## 프로젝트 구조

```text
ON_P_VS_AWS/
├── msa_shoply/       # Shoply MSA 애플리케이션, Docker, K8s 매니페스트
├── load-test/        # k6 시나리오, 부하테스트 서버, Grafana 대시보드
├── monitoring/       # 모니터링 구성
├── on-pre/           # 온프레미스 환경 문서 및 구성
├── aws/              # AWS/EKS 환경 문서 및 구성
├── cicd/             # GitHub Actions, GHCR, 배포 자동화 문서
└── docs/             # 실험 계획, 운영 가이드, 트러블슈팅
```

## 주요 문서

| 문서 | 용도 |
|---|---|
| [msa_shoply/README.md](msa_shoply/README.md) | Shoply 앱 구조와 로컬 실행 |
| [msa_shoply/k8s/README.md](msa_shoply/k8s/README.md) | K8s, Kustomize, ArgoCD 배포 |
| [load-test/k6/README.md](load-test/k6/README.md) | k6 시나리오 실행 |
| [load-test/server/README.md](load-test/server/README.md) | 부하테스트 서버와 모니터링 스택 |
| [cicd/README.md](cicd/README.md) | GHCR, GitHub Actions |
| [docs/experiment-plan.md](docs/experiment-plan.md) | 온프레미스 vs EKS 실험 계획 |

## 현재 부하테스트 기준

현재 실행 대상 k6 시나리오는 아래 3개다.

- `shoply-smoke.js`: 로그인, 상품 조회, 통계 API 연결 확인
- `shoply-order-payment.js`: 주문/결제 API 집중 부하
- `scenario-1-stable-order-payment.js`: 시나리오 1: 안정적인 평상시 기준선 테스트

현재 계획 중인 실험 시나리오는 아래 3개다.

| 시나리오 | 목적 | 흐름 |
|---|---|---|
| 1. 안정적인 상황 | 평상시 기준선 확인 | 로그인 -> 상품 조회 -> 주문 -> 결제 |
| 2. 스파이크 | 갑자기 주문이 몰릴 때 확인 | 로그인 -> 상품 조회 -> 주문 -> 결제를 짧은 시간에 증가 |
| 3. 노드 하나 끄기 | 장애 상황 복구 확인 | 부하 유지 중 워커 노드 1개 종료 |

이전 API 기준의 legacy `scenario-1`부터 `scenario-4`는 현재 API와 맞지 않아 `load-test/k6/deprecated/`에 참고용으로 보관한다.
