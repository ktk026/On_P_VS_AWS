# Shoply MSA

Shoply는 온프레미스 Kubernetes와 AWS EKS 비교 실험에 사용하는 MSA 쇼핑몰 애플리케이션이다. 상품 조회, 재고 예약, 주문 생성, 결제 처리, 로그인 흐름을 분리된 서비스로 구성한다.

## 서비스 구성

| 서비스 | 포트 | 역할 |
|---|---:|---|
| frontend | 3000 | 사용자 화면 |
| gateway | 4000 | API Gateway, 서비스 라우팅 |
| product | 4001 | 상품 목록/상세, 타임세일 |
| inventory | 4002 | 재고 조회, 예약, 차감, 해제 |
| order | 4003 | 주문 생성, 주문 상태 |
| payment | 4004 | Mock 결제, 결제 통계 |
| user | 4005 | 로그인, 사용자 인증 |
| postgres | 5432 | 영속 데이터 |
| redis | 6379 | 캐시 |

## 주요 API

| API | 설명 |
|---|---|
| `POST /api/auth/login` | 로그인, JWT 발급 |
| `GET /api/products` | 상품 목록 조회 |
| `GET /api/products/:id` | 상품 상세 조회 |
| `POST /api/orders` | 주문 생성, 재고 예약 |
| `POST /api/payments` | 결제 처리 |
| `GET /api/stats` | 결제 성공/실패 통계 |

현재 주문 API는 아래 payload를 사용한다.

```json
{
  "items": [
    {
      "productId": "uuid",
      "size": 260,
      "quantity": 1
    }
  ]
}
```

현재 결제 API는 아래 payload를 사용한다.

```json
{
  "orderId": "uuid",
  "method": "card"
}
```

## 로컬 실행

```bash
cd msa_shoply
cp .env.example .env
docker compose up -d
```

접속:

```text
Frontend: http://localhost:3000
Gateway:  http://localhost:4000
```

## 이미지 배포

GHCR 기준 이미지 빌드와 push는 스크립트를 사용한다.

```bash
cd msa_shoply
./scripts/push-ghcr.sh
```

GHCR 로그인에는 GitHub username과 `write:packages`, `read:packages` 권한이 있는 PAT이 필요하다. 토큰, `.env`, `.pem`, `.docker-config`는 Git에 올리지 않는다.

## Kubernetes

Kubernetes 배포 문서는 [k8s/README.md](k8s/README.md)를 참고한다.
