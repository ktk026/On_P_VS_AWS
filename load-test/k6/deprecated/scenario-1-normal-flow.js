import http from 'k6/http';
import { check, sleep } from 'k6';

import {
  BASE_URL,
  COMMON_THRESHOLDS,
  DEFAULT_HEADERS,
} from './config.js';

export const options = {
  scenarios: {
    normal_flow: {
      executor: 'ramping-arrival-rate',

      // 시작 요청률
      startRate: 100,

      // 초당 요청 기준
      timeUnit: '1s',

      // 미리 확보할 VU
      preAllocatedVUs: 100,

      // 최대 VU
      maxVUs: 300,

      // 20분 시나리오
      stages: [
        // 0~5분
        { target: 100, duration: '5m' },

        // 5~15분
        { target: 200, duration: '10m' },

        // 15~20분
        { target: 200, duration: '5m' },
      ],
    },
  },

  thresholds: COMMON_THRESHOLDS,
};

export default function () {
  // 1. 로그인
  const loginPayload = JSON.stringify({
    email: 'user1@test.com',
    password: '1234',
  });

  const loginRes = http.post(
    `${BASE_URL}/api/auth/login`,
    loginPayload,
    {
      headers: DEFAULT_HEADERS,
    }
  );

  check(loginRes, {
    'login success': (r) => r.status === 200,
  });

  let token = null;

  try {
    token = loginRes.json('token');
  } catch (e) {
    token = null;
  }

  // 인증 헤더
  const authHeader = token
    ? {
        ...DEFAULT_HEADERS,
        Authorization: `Bearer ${token}`,
      }
    : DEFAULT_HEADERS;

  // 2. 상품 목록 조회
  const productsRes = http.get(
    `${BASE_URL}/api/products`,
    {
      headers: authHeader,
    }
  );

  check(productsRes, {
    'products loaded': (r) => r.status === 200,
  });

  // 3. 상품 상세 조회
  const productDetailRes = http.get(
    `${BASE_URL}/api/products/1`,
    {
      headers: authHeader,
    }
  );

  check(productDetailRes, {
    'product detail loaded': (r) => r.status === 200,
  });

  // 사용자 행동 대기
  sleep(1);
}