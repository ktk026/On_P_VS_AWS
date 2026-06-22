# Shoply Load Test Server

이 디렉토리는 부하테스트 서버에 올릴 k6 + Prometheus + Grafana 패키지다. EC2에 Docker만 설치되어 있으면 Compose로 모니터링 스택과 k6 실행 환경을 함께 올릴 수 있다.

## 구성

| 구성 | 역할 | 기본 포트 |
|---|---|---:|
| k6 | Shoply API 부하 발생 | 없음 |
| Prometheus | k6, 서버, 컨테이너 메트릭 저장 | 9090 |
| Grafana | 대시보드 시각화 | 3000 |
| Node Exporter | EC2 CPU, RAM, Disk, Network 수집 | 9100 |
| cAdvisor | Docker 컨테이너 CPU, RAM, Network 수집 | 8080 |

## 서버 준비

Ubuntu 예시:

```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl git
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker "$USER"
```

설치 후 재접속하거나 아래 명령으로 Docker 권한을 반영한다.

```bash
newgrp docker
```

## 서버로 옮길 파일

`server/docker-compose.yml`이 `../k6`를 빌드 컨텍스트로 사용하므로 `load-test` 폴더 전체를 옮긴다.

```text
load-test/
├── k6/
└── server/
```

## 모니터링 스택 실행

```bash
cd load-test/server
cp .env.example .env
docker compose build
docker compose up -d prometheus grafana node-exporter cadvisor
```

상태 확인:

```bash
docker compose ps
```

접속:

```text
Grafana:    http://<LOAD_TEST_SERVER_IP>:3000
Prometheus: http://<LOAD_TEST_SERVER_IP>:9090
cAdvisor:   http://<LOAD_TEST_SERVER_IP>:8080
```

Grafana 기본 로그인:

```text
admin / admin
```

## k6 실행

기본 시나리오는 `shoply-order-payment.js`다.

```bash
BASE_URL=http://<SHOPLY_TARGET> \
TEST_RUN_ID=server-order-payment-100vus-5m \
VUS=100 \
DURATION=5m \
docker compose --profile run run --rm k6
```

시나리오 1 안정적인 상황 테스트:

```bash
BASE_URL=http://<SHOPLY_TARGET> \
TEST_RUN_ID=server-stable-flow \
SCENARIO=scenario-1-stable-order-payment.js \
docker compose --profile run run --rm k6
```

`scenario-1-stable-order-payment.js`는 VU별로 테스트 계정을 자동 배정한다.

```text
VU 1 -> test1@shoply.com
VU 2 -> test2@shoply.com
```

기본값 `ACCOUNT_COUNT=2000`을 유지하면 실제 VU 수만큼만 계정이 사용된다.

같은 Compose 네트워크 안에서 k6가 Prometheus로 remote write를 보내므로 기본값은 아래 내부 주소를 사용한다.

```text
http://prometheus:9090/api/v1/write
```

외부 Prometheus로 보낼 때만 덮어쓴다.

```bash
K6_PROMETHEUS_RW_SERVER_URL=http://<PROMETHEUS_IP>:9090/api/v1/write
```

## 결과 저장 위치

```text
load-test/k6/results/server/<TEST_RUN_ID>/
├── summary.json
└── summary.md
```

## 포트 요청

부하테스트 서버 보안그룹 인바운드:

| 포트 | 용도 | 비고 |
|---:|---|---|
| 22 | SSH | 관리자 IP만 허용 권장 |
| 3000 | Grafana | 대시보드 접속 |
| 9090 | Prometheus | 필요 시만 오픈 |
| 8080 | cAdvisor | 필요 시만 오픈 |
| 9100 | Node Exporter | 보통 외부 오픈 불필요 |

아웃바운드:

| 대상 | 용도 |
|---|---|
| Shoply target | 부하 대상 |
| Docker Hub, gcr.io | Docker 이미지 pull |

## Grafana 대시보드

Grafana에서 `Dashboards > New > Import`로 아래 ID를 가져올 수 있다.

| 목적 | Dashboard ID |
|---|---:|
| Node Exporter Full | 1860 |
| Docker/cAdvisor | 14282 |
| Docker/cAdvisor 대안 | 15798 |
| k6 Prometheus 공식 대시보드 | 19665 |

이 패키지에는 Shoply 주문/결제 부하 전용 대시보드도 자동 provision된다.

```text
Shoply Load Test / Shoply Order Payment Load
```

## 확인 순서

1. `docker compose ps`에서 모니터링 컨테이너가 `Up`인지 확인
2. `http://<LOAD_TEST_SERVER_IP>:9090/targets`에서 target이 `UP`인지 확인
3. Grafana에서 Prometheus datasource 확인
4. k6 테스트 실행
5. Grafana에서 `Shoply Order Payment Load` 또는 `k6 Prometheus` 대시보드 확인
