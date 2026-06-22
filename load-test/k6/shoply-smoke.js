import http from 'k6/http';
import { check, group, sleep } from 'k6';

import { BASE_URL, COMMON_THRESHOLDS, DEFAULT_HEADERS } from './config.js';

export const options = {
  vus: Number(__ENV.VUS || 5),
  duration: __ENV.DURATION || '30s',
  thresholds: COMMON_THRESHOLDS,
};

const TEST_EMAIL = __ENV.TEST_EMAIL || 'test1@shoply.com';
const TEST_PASSWORD = __ENV.TEST_PASSWORD || 'Test1234!';

export default function () {
  let token = '';
  let products = [];

  group('login', () => {
    const res = http.post(
      `${BASE_URL}/api/auth/login`,
      JSON.stringify({ email: TEST_EMAIL, password: TEST_PASSWORD }),
      { headers: DEFAULT_HEADERS },
    );

    check(res, {
      'login status is 200': (r) => r.status === 200,
      'login has token': (r) => Boolean(r.json('token')),
    });

    token = res.json('token') || '';
  });

  const headers = token
    ? { ...DEFAULT_HEADERS, Authorization: `Bearer ${token}` }
    : DEFAULT_HEADERS;

  group('browse products', () => {
    const res = http.get(`${BASE_URL}/api/products`, { headers });

    check(res, {
      'products status is 200': (r) => r.status === 200,
      'products list is not empty': (r) => Array.isArray(r.json()) && r.json().length > 0,
    });

    products = res.json() || [];
  });

  if (products.length > 0) {
    const product = products[Math.floor(Math.random() * products.length)];

    group('product detail', () => {
      const res = http.get(`${BASE_URL}/api/products/${product.id}`, { headers });

      check(res, {
        'detail status is 200': (r) => r.status === 200,
        'detail has sizes': (r) => Array.isArray(r.json('sizes')) && r.json('sizes').length > 0,
      });
    });
  }

  group('stats', () => {
    const res = http.get(`${BASE_URL}/api/stats`, { headers });
    check(res, {
      'stats status is 200': (r) => r.status === 200,
    });
  });

  sleep(1);
}
