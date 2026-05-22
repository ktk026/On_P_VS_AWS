# k6 Load Test Scenarios

## 개요

본 디렉토리는  
온프레미스 Kubernetes 환경과 AWS EKS 환경을 동일 조건으로 비교하기 위한 k6 부하테스트 시나리오를 관리한다.

이번 프로젝트의 핵심 목표는:

> "동일한 애플리케이션, 동일한 트래픽 조건에서  
> 온프레미스 k8s와 AWS EKS의 운영 특성 차이를 비교하는 것"

이다.

따라서:
- 동일한 Docker 이미지
- 동일한 k6 스크립트
- 동일한 RPS
- 동일한 실행 시간
- 동일한 API 비율

을 유지하여 실험 공정성을 확보한다.

---

# 디렉토리 구조

```text
load-test/
└── k6/
    ├── config.js
    ├── scenario-1-normal-flow.js
    ├── scenario-2-spike-order.js
    ├── scenario-3-ramp-up.js
    ├── scenario-4-failure-recovery.js
    └── README.md
```

---

# 공통 실행 방법

## 실행 환경

본 프로젝트는:
- 로컬 환경
- Docker 환경
- EC2 기반 환경

에서 실행 가능하다.

최종 실험은:
- 온프레미스 전용 Locust/k6 EC2
- AWS EKS 전용 Locust/k6 EC2

에서 동일 조건으로 수행한다.

---

# 실행 대상 변경 방식

모든 시나리오는:

```javascript
BASE_URL
```

환경변수를 기준으로 실행된다.

따라서:
- 스크립트는 완전히 동일
- 대상 주소만 변경

하여 실험 공정성을 유지한다.

---

## 온프레미스 테스트

```bash
BASE_URL=http://<ONPREM-LOADBALANCER-IP> \
k6 run scenario-1-normal-flow.js
```

---

## AWS EKS 테스트

```bash
BASE_URL=http://<EKS-ALB-DNS> \
k6 run scenario-1-normal-flow.js
```

---

# Docker 기반 실행 방법

로컬 또는 EC2에서 Docker 기반으로 k6를 실행할 수 있다.

## Docker 실행 예시

```bash
docker run --rm -i grafana/k6 run - < scenario-1-normal-flow.js
```

---

## Docker 기반 실행 이유

Docker 기반 실행을 사용하는 이유는:

- k6 버전 통일
- 실행 환경 차이 제거
- 로컬 PC 성능 차이 최소화
- 반복 실험 재현성 확보
- 팀원 간 동일 실행 환경 유지

를 위함이다.

---

# config.js

공통 설정 파일.

## 포함 내용

- BASE_URL
- 공통 Threshold
- 공통 Header

---

## 목적

온프레미스와 AWS EKS에서:
- 테스트 대상 주소만 변경
- 동일한 스크립트 재사용

을 가능하게 한다.

---

# 시나리오 구성 목적

이번 프로젝트의 시나리오는 단순 부하 생성이 목적이 아니다.

핵심 목적은:

```text
동일한 트래픽 상황에서
온프레미스 Kubernetes와 AWS EKS가
어떻게 다르게 반응하는가
```

를 데이터로 비교하는 것이다.

---

# Scenario 1 — Normal User Flow

## 목적

평상시 트래픽 상황에서:
- 온프레미스
- AWS EKS

모두 안정적으로 운영 가능한지 확인한다.

---

## 사용자 흐름

```text
로그인
→ 상품 목록 조회
→ 상품 상세 조회
```

실제 쇼핑몰 사용자의 일반적인 행동 흐름을 기반으로 구성한다.

---

## 트래픽 구성

| 구간 | RPS | 목적 |
|---|---:|---|
| 0~5분 | 100 | 워밍업 |
| 5~15분 | 200 | 정상 트래픽 유지 |
| 15~20분 | 200 | 안정성 관찰 |

---

## API 비율

| 엔드포인트 | 비율 |
|---|---:|
| GET /api/products | 70% |
| POST /api/orders | 20% |
| POST /api/payments | 10% |

---

## 핵심 관찰 항목

- Error Rate
- P95 Latency
- Pod Count
- CPU / Memory 사용률

---

## 전달 메시지

> "트래픽이 예측 가능하고 안정적이라면  
> 온프레미스 환경도 충분히 운영 가능하다."

---

# Scenario 2 — Spike Order Traffic

## 목적

타임세일 상황처럼 순간적으로 트래픽이 폭증할 때:
- 온프레미스
- AWS EKS

의 확장 및 운영 반응 차이를 비교한다.

---

## 핵심 서비스

- Product Service
- Inventory Service

---

## 트래픽 구성

| 구간 | RPS | 목적 |
|---|---:|---|
| 0~5분 | 100 | 정상 상태 유지 |
| 5분 | 1000 | 순간 폭증 |
| 5~15분 | 1000 | 폭증 유지 |
| 15~20분 | 1000 | 안정화 관찰 |

---

## API 비율

| 엔드포인트 | 비율 |
|---|---:|
| GET /api/products | 50% |
| POST /api/orders | 30% |
| POST /api/payments | 20% |

---

## 핵심 관찰 항목

- Pending Pod
- Error Rate
- Node Count
- HPA current vs desired
- P95 Latency

---

## 예상 결과

### 온프레미스

```text
HPA Pod 증가 시도
→ 노드 자원 부족
→ Pending Pod 증가
→ Error Rate 증가
```

---

### AWS EKS

```text
HPA Pod 증가
→ Karpenter Node 자동 추가
→ Pending 해소
→ 안정적 운영 유지
```

---

## 전달 메시지

> "운영 자동화와 확장 전략 차이가  
> 서비스 안정성 차이로 이어진다."

---

# Scenario 3 — Ramp-Up Load

## 목적

트래픽을 단계적으로 증가시키며:
- 시스템 한계점
- Auto Scaling 반응 시점

을 확인한다.

---

## 트래픽 구성

| 구간 | RPS |
|---|---:|
| 0~5분 | 100 |
| 5~10분 | 300 |
| 10~15분 | 500 |
| 15~20분 | 700 |
| 20~25분 | 1000 |

---

## 핵심 관찰 항목

- CPU 사용률
- Pending Pod 발생 시점
- HPA 반응 시점
- Node Count 증가 시점
- Error Rate 증가 시점

---

## 전달 메시지

> "문제는 현재 성능이 아니라  
> 증가하는 트래픽에 얼마나 유연하게 대응할 수 있는가이다."

---

# Scenario 4 — Failure Recovery

## 목적

피크 트래픽 상황에서 워커노드 장애 발생 시:
- 복구 속도
- 서비스 안정성
- 운영 효율성

차이를 비교한다.

---

## 장애 방식

테스트 중:
- 워커노드 2 강제 종료

를 수행한다.

---

## 트래픽 구성

| 구간 | 상태 |
|---|---|
| 0~5분 | 500 RPS 유지 |
| 5분 | 워커노드 2 강제 종료 |
| 5~15분 | 복구 과정 관찰 |
| 15~20분 | 정상화 여부 확인 |

---

## 핵심 관찰 항목

- MTTR
- Pending Pod
- 주문/결제 실패 건수
- Pod 재스케줄링 시간
- Node Count 변화

---

## 예상 결과

### 온프레미스

```text
재스케줄 시도
→ 자원 부족
→ Pending 증가
→ 복구 지연
```

---

### AWS EKS

```text
Karpenter 신규 노드 추가
→ Pod 재배치
→ 빠른 복구
```

---

## 전달 메시지

> "복구 시간이 곧 비즈니스 손실이다."

---

# 실험 공정성 기준

다음 항목은 반드시 동일하게 유지한다.

- 동일한 Docker 이미지
- 동일한 k6 스크립트
- 동일한 RPS
- 동일한 실행 시간
- 동일한 API 비율
- 동일한 Prometheus 지표
- 동일한 DB 스키마

---

# 핵심 비교 지표

| 지표 | 설명 |
|---|---|
| TPS | 초당 처리 요청 수 |
| P95 Latency | 사용자 체감 응답속도 |
| Error Rate | 5xx 에러 비율 |
| Pod Count | Running Pod 수 |
| Pending Pod | 자원 부족 상태 |
| Node Count | 노드 자동 증가 여부 |
| HPA current vs desired | Autoscaling 정상 여부 |
| CPU / Memory | 리소스 사용량 |

---

# 핵심 메시지

이번 프로젝트는 단순 성능 비교가 아니라:

```text
동일한 환경 조건에서
온프레미스 Kubernetes와 AWS EKS의
운영 특성 차이를 데이터로 비교하는 실험
```

이다.