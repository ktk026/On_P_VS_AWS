# Shoply App

쇼핑몰 MSA 앱 코드와 로컬 실행 구성을 정리한 문서다.

## 구성

| 경로 | 내용 |
|---|---|
| `gateway/` | API 게이트웨이 |
| `services/user/` | 사용자 / 인증 서비스 |
| `services/product/` | 상품 서비스 |
| `services/inventory/` | 재고 서비스 |
| `services/order/` | 주문 서비스 |
| `services/payment/` | 결제 서비스 |
| `frontend/` | React 쇼핑몰 UI |
| `db/` | 스키마, 시드, 부하테스트 준비 SQL |
| `docker-compose.yml` | 로컬 MSA 실행 구성 |
| `docker-compose.hub.yml` | 이미지 기반 실행 구성 |
| `.env.example` | 환경변수 예시 |

## 로컬 실행

루트 디렉토리에서 실행한다.

```bash
cp .env.example .env
docker compose up --build
```

기본 접속 포트:

| 서비스 | 포트 |
|---|---:|
| frontend | `3000` |
| gateway | `4000` |
| product | `4001` |
| inventory | `4002` |
| order | `4003` |
| payment | `4004` |
| user | `4005` |
| postgres | `5432` |
| redis | `6379` |

## 참고

`app` 브랜치의 루트 README 내용은 `dev` 브랜치의 전체 프로젝트 README와 역할이 달라 이 문서로 분리했다.
