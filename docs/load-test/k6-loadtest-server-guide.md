# k6 부하테스트 서버 구축 및 실행 가이드

## 목적

이 문서는 EC2 부하테스트 서버에서 k6, Prometheus, Grafana, Node Exporter, cAdvisor를 Docker Compose로 실행하는 절차를 정리한다.

## 서버 역할

| 구성 | 역할 |
|---|---|
| k6 | Shoply API에 부하를 발생시킨다 |
| Prometheus | k6, 서버, 컨테이너 메트릭을 저장한다 |
| Grafana | Prometheus 데이터를 대시보드로 시각화한다 |
| Node Exporter | EC2 CPU, 메모리, 디스크, 네트워크 메트릭을 수집한다 |
| cAdvisor | Docker 컨테이너 CPU, 메모리, 네트워크 메트릭을 수집한다 |

## 기본 설정

| 항목 | 값 |
|---|---|
| 부하 타겟 | `http://3.37.248.237` |
| Grafana 포트 | `3000` |
| Prometheus 포트 | `9090` |
| cAdvisor 포트 | `8080` |
| Node Exporter 포트 | `9100` |

## 서버에 필요한 패키지

Ubuntu 기준으로 Docker와 Docker Compose plugin을 설치한다.

```bash
sudo apt-get update
sudo apt-get install -y ca-certificates curl git
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
```

```bash
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

```bash
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

설치 확인:

```bash
docker --version
docker compose version
```

Docker 권한 설정:

```bash
sudo usermod -aG docker "$USER"
newgrp docker
```

## 서버로 옮길 파일

부하테스트 서버에는 `load-test` 폴더 전체를 옮긴다.

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

`load-test/server/docker-compose.yml`이 `../k6`를 빌드 컨텍스트로 사용하기 때문에 `server` 폴더만 단독으로 옮기면 k6 이미지 빌드가 실패한다.

## 모니터링 스택 실행

```bash
cd ~/load-test/server
cp .env.example .env
docker compose build
docker compose up -d prometheus grafana node-exporter cadvisor
```

컨테이너 상태 확인:

```bash
docker compose ps
```

## k6 부하테스트 실행

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

k6 실행 결과는 아래 경로에 저장된다.

```text
load-test/k6/results/server/<TEST_RUN_ID>/
├── summary.json
└── summary.md
```

## 접속 주소

`<LOAD_TEST_SERVER_PUBLIC_IP>`는 부하테스트 서버의 퍼블릭 IP로 바꾼다.

```text
Grafana:    http://<LOAD_TEST_SERVER_PUBLIC_IP>:3000
Prometheus: http://<LOAD_TEST_SERVER_PUBLIC_IP>:9090
cAdvisor:   http://<LOAD_TEST_SERVER_PUBLIC_IP>:8080
Node Exporter metrics: http://<LOAD_TEST_SERVER_PUBLIC_IP>:9100/metrics
```

Grafana 기본 계정:

```text
admin / admin
```

## 보안그룹 포트

인바운드:

| 포트 | 용도 | 권장 |
|---:|---|---|
| 22 | SSH | 관리자 IP만 허용 |
| 3000 | Grafana | 필요한 IP만 허용 |
| 9090 | Prometheus | 필요 시만 허용 |
| 8080 | cAdvisor | 필요 시만 허용 |
| 9100 | Node Exporter | 외부 오픈 비권장 |

아웃바운드:

| 대상 | 용도 |
|---|---|
| `3.37.248.237` | Shoply 부하 타겟 접근 |
| Docker Hub, gcr.io | Docker 이미지 다운로드 |

## Grafana 대시보드

자동 등록되는 대시보드:

```text
Shoply Load Test / Shoply Order Payment Load
```

추가로 Grafana Import에서 자주 쓰는 대시보드 ID:

| 목적 | Dashboard ID |
|---|---:|
| Node Exporter Full | 1860 |
| cAdvisor exporter | 14282 |
| Docker monitoring | 15798 |
| k6 Prometheus | 19665 |
