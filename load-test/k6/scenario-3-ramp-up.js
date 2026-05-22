import http from 'k6/http';
import { check, sleep } from 'k6';

import {
  BASE_URL,
  COMMON_THRESHOLDS,
  authHeaders,
} from './config.js';

export const options = {
  scenarios: {
    ramp_up_load: {
      executor: 'ramping-arrival-rate',

      // 시작 요청률
      startRate: 100,

      // 초당 요청 기준
      timeUnit: '1s',

      // 미리 확보할 VU
      preAllocatedVUs: 500,

      // 최대 VU
      maxVUs: 1500,

      // 점진적 증가 시나리오
      stages: [
        { target: 100, duration: '2m' },
        { target: 300, duration: '2m' },
        { target: 500, duration: '2m' },
        { target: 700, duration: '2m' },
        { target: 1000, duration: '2m' },

        // 최대 부하 유지 및 관찰
        { target: 1000, duration: '10m' },
      ],
    },
  },

  thresholds: COMMON_THRESHOLDS,
};

export default function () {
  const productId = Math.floor(Math.random() * 100) + 1;
  const userId = Math.floor(Math.random() * 1000) + 1;

  // 1. 상품 조회
  const productsRes = http.get(`${BASE_URL}/api/products`, {
    headers: authHeaders(),
  });

  check(productsRes, {
    'products status is 200': (r) => r.status === 200,
  });

  // 2. 주문 생성
  const orderPayload = JSON.stringify({
    userId,
    productId,
    quantity: 1,
  });

  const orderRes = http.post(
    `${BASE_URL}/api/orders`,
    orderPayload,
    {
      headers: authHeaders(),
    }
  );

  check(orderRes, {
    'order status is 200 or 201': (r) =>
      r.status === 200 || r.status === 201,
  });

  let orderId = null;

  try {
    orderId = orderRes.json('orderId') || orderRes.json('id');
  } catch (e) {
    orderId = null;
  }

  // 3. 결제 요청
  if (orderId) {
    const paymentPayload = JSON.stringify({
      orderId,
      userId,
      amount: 10000,
    });

    const paymentRes = http.post(
      `${BASE_URL}/api/payments`,
      paymentPayload,
      {
        headers: authHeaders(),
      }
    );

    check(paymentRes, {
      'payment status is 200 or 201': (r) =>
        r.status === 200 || r.status === 201,
    });
  }

  sleep(1);
}