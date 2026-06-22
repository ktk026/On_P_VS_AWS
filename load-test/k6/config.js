export const BASE_URL = __ENV.BASE_URL || 'http://localhost:4000';

export const FIXED_TOKEN = __ENV.FIXED_TOKEN || '';

export const COMMON_THRESHOLDS = {
  http_req_failed: ['rate<0.05'],
  http_req_duration: ['p(95)<1000'],
};

export const DEFAULT_HEADERS = {
  'Content-Type': 'application/json',
};

export function authHeaders() {
  return {
    ...DEFAULT_HEADERS,
    Authorization: `Bearer ${FIXED_TOKEN}`,
  };
}