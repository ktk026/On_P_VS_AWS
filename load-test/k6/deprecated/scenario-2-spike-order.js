import http from 'k6/http';
import { check, sleep } from 'k6';

import {
  BASE_URL,
  COMMON_THRESHOLDS,
  authHeaders,
} from './config.js';

export const options = {
  scenarios: {
    spike_order: {
      executor: 'ramping-arrival-rate',
      startRate: 100,
      timeUnit: '1s',
      preAllocatedVUs: 500,
      maxVUs: 1500,
    stages: [
        { target: 100, duration: '5m' },
        { target: 1000, duration: '1s' },
        { target: 1000, duration: '15m' },
],
    },
  },
  thresholds: COMMON_THRESHOLDS,
};

export default function () {
  const productId = Math.floor(Math.random() * 100) + 1;
  const userId = Math.floor(Math.random() * 1000) + 1;

  const productsRes = http.get(`${BASE_URL}/api/products`, {
    headers: authHeaders(),
  });

  check(productsRes, {
    'products status is 200': (r) => r.status === 200,
  });

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
    'order status is 200 or 201': (r) => r.status === 200 || r.status === 201,
  });

  let orderId = null;

  try {
    orderId = orderRes.json('orderId') || orderRes.json('id');
  } catch (e) {
    orderId = null;
  }

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
      'payment status is 200 or 201': (r) => r.status === 200 || r.status === 201,
    });
  }

  sleep(1);
}
