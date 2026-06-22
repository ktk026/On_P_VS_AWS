import http from 'k6/http';
import { check, sleep } from 'k6';

function think(min, max) {
  sleep(min + Math.random() * (max - min));
}

const BASE_URL = __ENV.BASE_URL || 'http://localhost';
const ACCOUNT_COUNT = Number(__ENV.ACCOUNT_COUNT || 2000);
const TEST_PASSWORD = __ENV.TEST_PASSWORD || 'Test1234!';
const LOAD_PROFILE = __ENV.LOAD_PROFILE || 'ramp';
const FIXED_VUS = Number(__ENV.VUS || 10);
const FIXED_DURATION = __ENV.DURATION || '5m';

let cachedToken = '';

function safeJson(res, path) {
  try {
    return path ? res.json(path) : res.json();
  } catch {
    return null;
  }
}

function randomItem(items) {
  return items[Math.floor(Math.random() * items.length)];
}

function pickProduct(products) {
  if (!Array.isArray(products) || products.length === 0) {
    return null;
  }

  const availableProducts = products.filter((product) => (
    product?.id && Number(product.total_available ?? product.totalAvailable ?? 0) > 0
  ));

  return availableProducts.length > 0 ? randomItem(availableProducts) : null;
}

function getUser() {
  const userNumber = ((__VU - 1) % ACCOUNT_COUNT) + 1;

  return {
    email: `test${userNumber}@shoply.com`,
    password: TEST_PASSWORD,
  };
}

function getAuthHeaders() {
  if (!cachedToken) {
    const user = getUser();
    const loginRes = http.post(
      `${BASE_URL}/api/auth/login`,
      JSON.stringify({ email: user.email, password: user.password }),
      {
        headers: { 'Content-Type': 'application/json' },
        tags: { name: 'POST /api/auth/login', flow: 'scenario_1_stable' },
      },
    );

    check(loginRes, {
      'login status is 200': (r) => r.status === 200,
      'login has token': (r) => Boolean(safeJson(r, 'token')),
    });

    cachedToken = loginRes.status === 200 ? safeJson(loginRes, 'token') : '';
  }

  return {
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${cachedToken}`,
    },
    tags: { flow: 'scenario_1_stable' },
  };
}

const thresholds = {
  http_req_duration: ['p(95)<3000'],
  http_req_failed: ['rate<0.3'],
};

const rampOptions = {
  scenarios: {
    ramp: {
      executor: 'ramping-vus',
      startVUs: 0,
      stages: [
        { duration: '1m', target: 50 },
        { duration: '1m', target: 100 },
        { duration: '1m', target: 150 },
        { duration: '1m', target: 200 },
        { duration: '1m', target: 250 },
        { duration: '2m', target: 300 },
        { duration: '2m', target: 300 },
        { duration: '1m', target: 0 },
      ],
      gracefulRampDown: '30s',
    },
  },
  thresholds,
};

const constantOptions = {
  scenarios: {
    stable_constant: {
      executor: 'constant-vus',
      vus: FIXED_VUS,
      duration: FIXED_DURATION,
    },
  },
  thresholds,
};

// Scenario 1: stable baseline.
// Login -> home/products -> product detail -> order -> payment.
// Default LOAD_PROFILE=ramp shows the baseline and limit approach in one run.
// LOAD_PROFILE=constant is useful for step-by-step limit checks.
export const options = LOAD_PROFILE === 'constant' ? constantOptions : rampOptions;

export default function () {
  const authHeaders = getAuthHeaders();

  if (!cachedToken) {
    think(0.5, 1.0);
    return;
  }

  const homeRes = http.get(`${BASE_URL}/`);
  check(homeRes, { 'home status is 200': (r) => r.status === 200 });
  think(0.5, 1.0);

  const productsRes = http.get(`${BASE_URL}/api/products`, {
    ...authHeaders,
    tags: { name: 'GET /api/products', flow: 'scenario_1_stable' },
  });
  const productsOk = check(productsRes, {
    'products list status is 200 or 304': (r) => r.status === 200 || r.status === 304,
  });

  if (!productsOk) return;

  think(0.3, 0.8);

  const productsPayload = safeJson(productsRes);
  const products = Array.isArray(productsPayload) ? productsPayload : productsPayload?.products;
  const selectedProduct = pickProduct(products);
  const productSelected = check(selectedProduct, {
    'product selected': (p) => p !== null,
  });

  if (!productSelected || !selectedProduct) return;

  const productId = selectedProduct.id;
  const productRes = http.get(`${BASE_URL}/api/products/${productId}`, {
    ...authHeaders,
    tags: { name: 'GET /api/products/:id', flow: 'scenario_1_stable' },
  });
  check(productRes, { 'product detail status is 200 or 304': (r) => r.status === 200 || r.status === 304 });

  if (productRes.status !== 200) return;

  think(0.5, 1.5);

  const productPayload = safeJson(productRes);
  const product = productPayload?.product ?? productPayload;
  const availableSizes = product.sizes ? product.sizes.filter((s) => s.available > 0) : [];

  if (availableSizes.length === 0) return;

  const selectedSize = availableSizes[Math.floor(Math.random() * availableSizes.length)];

  const orderRes = http.post(
    `${BASE_URL}/api/orders`,
    JSON.stringify({
      items: [{ productId, size: selectedSize.size, quantity: 1 }],
    }),
    {
      ...authHeaders,
      tags: { name: 'POST /api/orders', flow: 'scenario_1_stable' },
    },
  );
  check(orderRes, {
    'order status is 201': (r) => r.status === 201,
    'orderId exists': (r) => Boolean(safeJson(r, 'orderId')),
  });

  if (orderRes.status !== 201) return;

  const orderId = safeJson(orderRes, 'orderId');
  if (!orderId) return;

  const paymentRes = http.post(
    `${BASE_URL}/api/payments`,
    JSON.stringify({
      orderId,
      method: Math.random() < 0.8 ? 'card' : 'bank',
    }),
    {
      ...authHeaders,
      tags: { name: 'POST /api/payments', flow: 'scenario_1_stable' },
    },
  );

  check(paymentRes, {
    'payment status is 200': (r) => r.status === 200,
    'paymentId exists': (r) => Boolean(safeJson(r, 'paymentId')),
    'payment has status': (r) => {
      return ['PAID', 'FAILED'].includes(String(safeJson(r, 'status')));
    },
  });
}
