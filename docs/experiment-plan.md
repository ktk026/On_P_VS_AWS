# Experiment Plan

온프레미스 Kubernetes와 AWS EKS를 동일 애플리케이션, 동일 부하 조건에서 비교하기 위한 실험 계획이다.

## 실험 목적

이 실험은 단순히 어느 환경이 더 빠른지 비교하는 것이 아니다.

핵심은 아래 차이를 데이터로 보여주는 것이다.

```text
온프레미스: 고정 노드 + HPA
AWS EKS: HPA + Karpenter 노드 자동 확장
```

온프레미스에서 Pending Pod가 쌓이고 Error Rate가 증가하는 것은 실패가 아니라, 고정 자원 환경의 한계점을 측정하는 핵심 현상이다.

## 공정성 기준

| 항목 | 기준 |
|---|---|
| 애플리케이션 | 동일 Shoply 코드 |
| 이미지 | 동일 GHCR 이미지 태그 |
| 부하 | 동일 k6 스크립트 |
| 시간 | 동일 테스트 시간 |
| DB 스키마 | 동일 스키마와 초기 데이터 |
| 지표 | 동일 Prometheus/Grafana 기준 |

이미지 태그는 `latest`를 피하고 커밋 SHA 또는 실험용 고정 태그를 사용한다.

## 관찰 지표

| 지표 | 의미 |
|---|---|
| TPS / RPS | 초당 처리량 |
| P95 latency | 사용자 체감 응답 지연 |
| Error Rate | 실패율 |
| Pod Count | Running Pod 수 |
| Pending Pod | 노드 자원 부족 여부 |
| Node Count | EKS Karpenter 확장 여부 |
| HPA current/desired | 원하는 replica와 실제 replica 차이 |
| CPU / Memory | 노드와 컨테이너 자원 사용량 |

## 현재 k6 시나리오

현재 실행 가능한 시나리오는 `load-test/k6` 아래 파일과 `load-test/k6/scripts` 아래 실험용 스크립트다.

| 파일 | 목적 |
|---|---|
| `shoply-smoke.js` | 연결 확인 |
| `shoply-order-payment.js` | 주문/결제 API 집중 부하 |
| `scenario-1-stable-order-payment.js` | 시나리오 1: 안정적인 평상시 기준선 테스트 |
| `scripts/stable-flow.js` | k6 서버 직접 실행용 안정 상황 E2E 테스트 |
| `scripts/spike-flow.js` | k6 서버 직접 실행용 스파이크 E2E 테스트 |
| `scripts/failover-flow.js` | k6 서버 직접 실행용 장애 복구 E2E 테스트 |

이전 API 기준의 legacy `scenario-1`부터 `scenario-4`는 현재 API와 맞지 않아 deprecated 처리했다.

## 시나리오 1: 안정적인 상황

목적:

- 평상시 기준선 확인
- 로그인, 상품 조회, 주문, 결제 흐름이 안정적으로 동작하는지 확인
- 온프레미스와 EKS 모두 정상 트래픽에서는 운영 가능한지 비교

실행 파일:

```text
scenario-1-stable-order-payment.js
scripts/stable-flow.js
```

주요 확인:

- 로그인 성공률
- 주문 성공률
- 결제 처리율
- P95 latency
- Error Rate
- Pod CPU/Memory

현재 램프:

```text
1분 50 VU
1분 100 VU
1분 150 VU
1분 200 VU
1분 250 VU
2분 300 VU
2분 300 VU 유지
1분 0 VU
```

k6 서버에서 Docker 이미지를 바로 실행하는 경우에는 `scripts/stable-flow.js`를 사용한다. 이 스크립트는 100 VU에서 시작해 300 VU까지 올린 뒤 300 VU를 유지한다.

## 시나리오 2: 스파이크

목적:

- 갑자기 주문이 몰릴 때 환경별 반응 확인
- 짧은 시간에 로그인, 상품 조회, 주문, 결제 트래픽 증가
- HPA와 Karpenter 반응 차이 관찰

실행 파일:

```text
scripts/spike-flow.js
```

주요 확인:

- Error Rate 급증 여부
- P95 latency 증가 여부
- HPA current/desired 차이
- Pending Pod 발생 여부
- EKS Node Count 증가 여부

## 시나리오 3: 노드 하나 끄기

장애 복구 테스트는 현재 deprecated 시나리오를 그대로 쓰지 않는다. 시나리오 1의 실제 사용자 흐름을 기반으로 중간 부하를 유지한 뒤, 워커 노드 하나를 중지하는 방식으로 진행한다.

실행 파일:

```text
scripts/failover-flow.js
```

진행 방식:

```text
k6 서버에서 failover-flow.js 실행
-> 400 VU 유지 구간 진입 확인
-> 워커 노드 1개 중지
-> Grafana/Prometheus/Event log로 복구 과정 관찰
```

확인 항목:

- MTTR
- Pending Pod
- 주문/결제 실패 건수
- Pod 재스케줄링 시간
- EKS Node Count 증가 시점

## 발표 메시지

평상시 트래픽에서는 온프레미스도 충분히 안정적으로 운영될 수 있다.

차이는 트래픽이 급증하거나 장애가 발생했을 때 나타난다. 온프레미스는 고정 자원의 한계가 Pending Pod와 Error Rate로 드러나고, EKS는 Karpenter를 통해 노드를 추가하며 복구/확장을 자동화한다.
