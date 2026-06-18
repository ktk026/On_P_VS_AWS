# Deprecated k6 Scenarios

이 폴더의 시나리오는 이전 Shoply API 기준으로 작성된 참고용 파일이다.

현재 Shoply 주문/결제 API는 아래 형태를 사용한다.

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

결제 API는 아래 형태를 사용한다.

```json
{
  "orderId": "uuid",
  "method": "card"
}
```

이 폴더의 legacy `scenario-1`부터 `scenario-4`는 숫자 상품 ID와 예전 주문/결제 payload를 사용하므로
현재 부하테스트 실행 대상에서 제외한다.

현재 실행 대상은 상위 폴더의 아래 파일이다.

- `shoply-smoke.js`
- `shoply-order-payment.js`
- `scenario-1-stable-order-payment.js`
