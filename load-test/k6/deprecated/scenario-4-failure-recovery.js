import http from 'k6/http';
import { check, sleep } from 'k6';

import {
  BASE_URL,
  COMMON_THRESHOLDS,
  DEFAULT_HEADERS,
} from './config.js';

export const options = {
  scenarios: {
    failure_recovery: {
      executor: 'constant-arrival-rate',
      rate: 500,
      timeUnit: '1s',
      duration: '20m',
      preAllocatedVUs: 500,
      maxVUs: 1500,
    },
  },
  thresholds: COMMON_THRESHOLDS,
};

export default function () {
  const productId = Math.floor(Math.random() * 100) + 1;
  const userId = Math.floor(Math.random() * 1000) + 1;

  const orderPayload = JSON.stringify({
    userId,
    productId,
    quantity: 1,
  });

  const orderRes = http.post(
    `${BASE_URL}/api/orders`,
    orderPayload,
    {
      headers: DEFAULT_HEADERS,
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
        headers: DEFAULT_HEADERS,
      }
    );

    check(paymentRes, {
      'payment status is 200 or 201': (r) => r.status === 200 || r.status === 201,
    });
  }

  sleep(1);
}