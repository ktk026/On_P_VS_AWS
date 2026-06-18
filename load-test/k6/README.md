# k6 Load Test Scenarios

이 디렉토리는 Shoply 부하테스트 시나리오와 k6 Docker 이미지를 관리한다.

## 현재 실행 대상

| 파일 | 용도 |
|---|---|
| `shoply-smoke.js` | 로그인, 상품 조회, 상품 상세, 통계 API 연결 확인 |
| `shoply-order-payment.js` | 주문/결제 API 집중 부하테스트 |
| `scenario-1-stable-order-payment.js` | 시나리오 1: 안정적인 평상시 기준선 테스트 |

`deprecated/` 아래 `scenario-1`부터 `scenario-4`는 이전 API 기준으로 작성된 참고용 파일이다. 현재 실험에는 사용하지 않는다.

## 실험 시나리오 계획

| 시나리오 | 목적 | 흐름 | 상태 |
|---|---|---|---|
| 1. 안정적인 상황 | 평상시 기준선 확인 | 로그인 -> 상품 조회 -> 주문 -> 결제 | `scenario-1-stable-order-payment.js` |
| 2. 스파이크 | 갑자기 주문이 몰릴 때 확인 | 로그인 -> 상품 조회 -> 주문 -> 결제를 짧은 시간에 증가 | 작성 예정 |
| 3. 노드 하나 끄기 | 장애 상황 복구 확인 | 부하 유지 중 워커 노드 1개 종료 | 작성 예정 |

이전 API 기준으로 작성된 legacy `scenario-1`부터 `scenario-4`는 `deprecated/`에 보관한다.

## 시나리오 선택 기준

| 목적 | 실행 파일 |
|---|---|
| 서버 연결 확인 | `shoply-smoke.js` |
| 주문/결제 처리량 비교 | `shoply-order-payment.js` |
| 시나리오 1 안정적인 기준선 | `scenario-1-stable-order-payment.js` |

`shoply-order-payment.js`는 `VUS`, `DURATION` 환경변수로 부하를 조절한다.

`scenario-1-stable-order-payment.js`는 기본적으로 50 -> 100 -> 150 -> 200 -> 250 -> 300 VU 램프가 정의되어 있다.

고정 VU로 한 단계씩 확인하고 싶으면 `LOAD_PROFILE=constant`를 사용한다.

## 테스트 계정 사용 방식

실제 사용자 흐름 시나리오는 VU별로 테스트 계정을 자동 배정한다.

```text
VU 1   -> test1@shoply.com
VU 2   -> test2@shoply.com
VU 300 -> test300@shoply.com
```

계정은 코드에 2000개를 직접 넣지 않고, 아래 환경변수로 계정 풀 크기만 조절한다.

| 변수 | 기본값 | 설명 |
|---|---:|---|
| `ACCOUNT_COUNT` | 2000 | 사용할 테스트 계정 풀 크기 |
| `TEST_PASSWORD` | `Test1234!` | 테스트 계정 공통 비밀번호 |

기본값 `ACCOUNT_COUNT=2000`을 유지하면 테스트 VU 수만큼만 계정이 사용된다.

```text
VUS=50  -> test1 ~ test50 사용
VUS=300 -> test1 ~ test300 사용
VUS=500 -> test1 ~ test500 사용
```

## Docker 이미지 빌드

```bash
cd /Users/kyu/Projects/On_P_VS_AWS
docker build -t shoply-k6-loadtest:local ./load-test/k6
```

EC2에서 사용할 이미지는 같은 Dockerfile로 빌드한다.

```bash
cd load-test/k6
docker compose build
```

## Docker Compose 실행

기본 서비스는 `order-payment`이며 기본 시나리오는 `shoply-order-payment.js`다.

```bash
cd load-test/k6

BASE_URL=http://<SHOPLY_TARGET> \
K6_PROMETHEUS_RW_SERVER_URL=http://<PROMETHEUS_IP>:9090/api/v1/write \
TEST_RUN_ID=order-payment-100vus-5m \
VUS=100 \
DURATION=5m \
docker compose run --rm order-payment
```

시나리오 1 안정적인 상황 테스트:

```bash
BASE_URL=http://<SHOPLY_TARGET> \
K6_PROMETHEUS_RW_SERVER_URL=http://<PROMETHEUS_IP>:9090/api/v1/write \
TEST_RUN_ID=stable-flow-300vus \
SCENARIO=scenario-1-stable-order-payment.js \
docker compose run --rm order-payment
```

시나리오 1 고정 VU 테스트:

```bash
BASE_URL=http://<SHOPLY_TARGET> \
K6_PROMETHEUS_RW_SERVER_URL=http://<PROMETHEUS_IP>:9090/api/v1/write \
TEST_RUN_ID=stable-flow-100vus-5m \
SCENARIO=scenario-1-stable-order-payment.js \
LOAD_PROFILE=constant \
VUS=100 \
DURATION=5m \
docker compose run --rm order-payment
```

Smoke test:

```bash
BASE_URL=http://<SHOPLY_TARGET> \
SCENARIO=shoply-smoke.js \
VUS=5 \
DURATION=30s \
docker compose run --rm order-payment
```

Compose profile로 실행할 수도 있다.

```bash
docker compose --profile scenarios run --rm smoke
docker compose --profile scenarios run --rm stable-flow
```

## 현재 EC2 실행 예시

최신 EC2 정보 기준 예시는 아래와 같다.

실행 전 PostgreSQL 서버에서 재고를 초기화한다.

```bash
docker exec -i shoply-postgres psql -U shoply -d shoply < ~/postgres/load-test-prep.sql
```

애플리케이션 EC2에서 이벤트 로그를 캡처하려면 별도 터미널에서 실행한다.

```bash
sudo -i
/home/ubuntu/scripts/capture-loop.sh shoply 30
```

부하테스트 서버에서 k6를 실행한다.

```bash
cd ~/load-test/k6

BASE_URL=http://54.180.167.159 \
K6_PROMETHEUS_RW_SERVER_URL=http://54.180.138.196:9090/api/v1/write \
TEST_RUN_ID=ec2-stable-flow \
SCENARIO=scenario-1-stable-order-payment.js \
docker compose run --rm order-payment
```

Smoke test:

```bash
BASE_URL=http://54.180.167.159 \
SCENARIO=shoply-smoke.js \
VUS=5 \
DURATION=30s \
docker compose run --rm order-payment
```

시나리오 1 고정 VU 테스트:

```bash
BASE_URL=http://54.180.167.159 \
K6_PROMETHEUS_RW_SERVER_URL=http://54.180.138.196:9090/api/v1/write \
TEST_RUN_ID=ec2-stable-flow-100vus-5m \
SCENARIO=scenario-1-stable-order-payment.js \
LOAD_PROFILE=constant \
VUS=100 \
DURATION=5m \
docker compose run --rm order-payment
```

주문/결제 API만 100명, 5분 테스트:

```bash
BASE_URL=http://54.180.167.159 \
K6_PROMETHEUS_RW_SERVER_URL=http://54.180.138.196:9090/api/v1/write \
TEST_RUN_ID=ec2-order-payment-100vus-5m \
VUS=100 \
DURATION=5m \
docker compose run --rm order-payment
```

주의: `PROMETHEUS_RW_URL`이 아니라 `K6_PROMETHEUS_RW_SERVER_URL`을 사용한다.
URL은 `http://<PROMETHEUS_IP>:9090/api/v1/write`처럼 `/api/v1/write`까지 포함해야 한다.

## 결과 저장

`shoply-order-payment.js`는 `handleSummary`로 결과 파일을 저장한다.

```text
load-test/k6/results/<TEST_RUN_ID>/
├── summary.json
└── summary.md
```

여러 실행 결과를 CSV/Markdown 비교표로 합치려면:

```bash
node load-test/k6/collect-order-payment-results.mjs
```

생성 파일:

```text
load-test/results/order-payment/order-payment-summary.csv
load-test/results/order-payment/order-payment-summary.md
```

## 해석 기준

`scenario-1-stable-order-payment.js`는 아래 흐름으로 평상시 기준선을 먼저 확인하고, 어느 구간부터 불안정해지는지 함께 관찰한다.

```text
50 VU → 100 VU → 150 VU → 200 VU → 250 VU → 300 VU 유지 → 0 VU
```

해석 예시:

- 200 VU까지 안정적이면 비교 기준 부하로 사용
- 250 VU부터 P95 latency가 증가하면 성능 한계 진입 구간
- 300 VU부터 Pending Pod가 발생하면 클러스터 자원 한계 구간
- 위 패턴이면 한계점은 250~300 VU 사이로 판단

별도 고정 VU 테스트로 한계점을 좁힐 때는 아래 순서로 진행한다.

```text
10 VU, 1분
50 VU, 3분
100 VU, 5분
200 VU, 5분
300 VU, 5분
500 VU, 5분
```

300 VU는 안정적이고 500 VU에서 불안정하면 바로 1000 VU로 가지 않고 350, 400, 450 VU를 추가 확인한다.

예시:

```bash
LOAD_PROFILE=constant VUS=10 DURATION=1m SCENARIO=scenario-1-stable-order-payment.js docker compose run --rm order-payment
LOAD_PROFILE=constant VUS=50 DURATION=3m SCENARIO=scenario-1-stable-order-payment.js docker compose run --rm order-payment
LOAD_PROFILE=constant VUS=100 DURATION=5m SCENARIO=scenario-1-stable-order-payment.js docker compose run --rm order-payment
LOAD_PROFILE=constant VUS=200 DURATION=5m SCENARIO=scenario-1-stable-order-payment.js docker compose run --rm order-payment
LOAD_PROFILE=constant VUS=300 DURATION=5m SCENARIO=scenario-1-stable-order-payment.js docker compose run --rm order-payment
LOAD_PROFILE=constant VUS=500 DURATION=5m SCENARIO=scenario-1-stable-order-payment.js docker compose run --rm order-payment
```

## 주의

- `PROMETHEUS_RW_URL`이 아니라 `K6_PROMETHEUS_RW_SERVER_URL`을 사용한다.
- `deprecated/`에 있는 legacy 시나리오는 실행하지 않는다.
- 토큰, `.env`, `.pem`, `.docker-config`는 Git에 올리지 않는다.
