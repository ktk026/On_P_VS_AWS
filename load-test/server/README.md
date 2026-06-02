# Shoply Load Test Server

이 폴더는 부하테스트 서버에 올릴 k6 + 모니터링 스택 패키지다.

## 구성

| 구성 | 역할 | 기본 포트 |
|---|---|---:|
| k6 | Shoply API 부하 발생 | 없음 |
| Prometheus | k6, 서버, 컨테이너 메트릭 저장 | 9090 |
| Grafana | 대시보드 시각화 | 3000 |
| Node Exporter | EC2 CPU, RAM, Disk, Network 수집 | 9100 |
| cAdvisor | Docker 컨테이너 CPU, RAM, Network 수집 | 8080 |

## 기본 타겟

| 항목 | 값 |
|---|---|
| 부하 대상 | `http://3.37.248.237` |
| k6 결과 수집 | `http://prometheus:9090/api/v1/write` |

같은 Docker Compose 네트워크 안에서 k6가 Prometheus로 직접 remote write를 보내므로, 기본값은 내부 주소 `prometheus:9090`을 사용한다.

## 서버 준비

부하테스트 서버에는 Docker와 Docker Compose plugin이 필요하다.

Ubuntu 예시:

```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl git
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker "$USER"
```

설치 후 세션을 다시 접속하거나 아래 명령으로 Docker 권한을 반영한다.

```bash
newgrp docker
```

## 서버로 옮길 파일

부하테스트 서버에는 `load-test` 폴더 전체를 옮기는 것을 권장한다.

```text
load-test/
├── k6/
│   ├── Dockerfile
│   ├── entrypoint.sh
│   ├── config.js
│   ├── shoply-order-payment.js
│   └── scenario-*.js
└── server/
    ├── docker-compose.yml
    ├── prometheus.yml
    ├── .env.example
    └── grafana/
```

`server/docker-compose.yml`이 `../k6`를 빌드 컨텍스트로 사용하므로 `server` 폴더만 단독으로 옮기면 k6 이미지 빌드가 안 된다.

## 실행

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

접속 주소:

```text
Grafana:    http://<LOAD_TEST_SERVER_IP>:3000
Prometheus: http://<LOAD_TEST_SERVER_IP>:9090
cAdvisor:   http://<LOAD_TEST_SERVER_IP>:8080
Node Exporter metrics: http://<LOAD_TEST_SERVER_IP>:9100/metrics
```

Grafana 기본 로그인:

```text
admin / admin
```

## k6 부하 실행

100명, 5분:

```bash
TEST_RUN_ID=server-100vus-5m VUS=100 DURATION=5m docker compose --profile run run --rm k6
```

400명, 5분:

```bash
TEST_RUN_ID=server-400vus-5m VUS=400 DURATION=5m docker compose --profile run run --rm k6
```

450명, 5분:

```bash
TEST_RUN_ID=server-450vus-5m VUS=450 DURATION=5m docker compose --profile run run --rm k6
```

다른 시나리오 실행:

```bash
TEST_RUN_ID=server-spike-order \
SCENARIO=scenario-2-spike-order.js \
docker compose --profile run run --rm k6
```

## 결과 저장 위치

k6 실행 결과는 아래에 저장된다.

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
| `3.37.248.237` | Shoply 부하 타겟 |
| Docker Hub, gcr.io | Docker 이미지 pull |

## Grafana 대시보드 템플릿 ID

Grafana에서 `Dashboards > New > Import`로 아래 ID를 가져오면 된다.

| 목적 | Dashboard ID |
|---|---:|
| 서버 자원 모니터링, Node Exporter Full | 1860 |
| Docker 컨테이너 모니터링, cAdvisor | 14282 |
| Docker 컨테이너 모니터링 대안 | 15798 |
| k6 Prometheus 공식 대시보드 | 19665 |

이 패키지에는 Shoply 주문/결제 부하 전용 대시보드도 자동 provision된다.

```text
Shoply Load Test / Shoply Order Payment Load
```

## 확인 순서

1. `docker compose ps`에서 네 모니터링 컨테이너가 `Up`인지 확인
2. `http://<LOAD_TEST_SERVER_IP>:9090/targets`에서 `prometheus`, `loadtest-node`, `loadtest-cadvisor`가 `UP`인지 확인
3. Grafana 접속 후 Prometheus datasource 확인
4. k6 테스트 실행
5. Grafana에서 `Shoply Order Payment Load` 또는 `k6 Prometheus` 대시보드 확인
