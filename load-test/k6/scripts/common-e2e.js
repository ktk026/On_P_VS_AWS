import http from 'k6/http';
import { check, sleep } from 'k6';

export const BASE_URL = __ENV.BASE_URL || 'http://localhost';
export const ACCOUNT_COUNT = Number(__ENV.ACCOUNT_COUNT || 2000);
export const TEST_PASSWORD = __ENV.TEST_PASSWORD || 'Test1234!';

const SIZES = [240, 250, 260, 270, 280, 290, 300];

let cachedToken = '';

export function think(min, max) {
  sleep(min + Math.random() * (max - min));
}

export function safeJson(res, path) {
  try {
    return path === undefined || path === null ? res.json() : res.json(path);
  } catch {
    return null;
  }
}

export function getUser() {
  const userNumber = ((__VU - 1) % ACCOUNT_COUNT) + 1;

  return {
    email: `test${userNumber}@shoply.com`,
    password: TEST_PASSWORD,
  };
}

export function randomItem(items) {
  return items[Math.floor(Math.random() * items.length)];
}

export function randomSize() {
  return randomItem(SIZES);
}

export function loginOnce() {
  if (cachedToken) {
    return cachedToken;
  }

  const user = getUser();
  const loginRes = http.post(
    `${BASE_URL}/api/auth/login`,
    JSON.stringify({
      email: user.email,
      password: user.password,
    }),
    {
      headers: { 'Content-Type': 'application/json' },
      tags: { name: 'POST /api/auth/login', api: 'login' },
    },
  );

  const loginOk = check(loginRes, {
    'login status is 200': (res) => res.status === 200,
    'login token exists': (res) => Boolean(safeJson(res, 'token')),
  });

  if (!loginOk || loginRes.status !== 200) {
    return '';
  }

  cachedToken = safeJson(loginRes, 'token') || '';
  return cachedToken;
}

export function pickProduct(products, mode = 'normal') {
  if (!Array.isArray(products) || products.length === 0) {
    return null;
  }

  const availableProducts = products.filter((product) => (
    product?.id && Number(product.total_available ?? product.totalAvailable ?? 0) > 0
  ));
  const candidates = availableProducts.length > 0 ? availableProducts : products;

  if (mode === 'timesale') {
    return randomItem(candidates.slice(0, Math.min(3, candidates.length)));
  }

  if (mode === 'normal') {
    return randomItem(candidates.slice(0, Math.min(20, candidates.length)));
  }

  return randomItem(candidates);
}

export function pickSize(product) {
  const availableSizes = Array.isArray(product?.sizes)
    ? product.sizes.filter((size) => Number(size.available ?? size.stock ?? 0) > 0)
    : [];

  if (availableSizes.length > 0) {
    return randomItem(availableSizes).size;
  }

  return randomSize();
}

export function runE2E(productMode = 'normal') {
  const token = loginOnce();

  if (!token) {
    think(0.5, 1.0);
    return;
  }

  const headers = {
    'Content-Type': 'application/json',
    Authorization: `Bearer ${token}`,
  };

  const productsRes = http.get(`${BASE_URL}/api/products`, {
    headers,
    tags: { name: 'GET /api/products', api: 'products-list' },
  });

  const productsOk = check(productsRes, {
    'products list status is 200 or 304': (res) => res.status === 200 || res.status === 304,
  });

  if (!productsOk) {
    think(0.5, 1.0);
    return;
  }

  const productsPayload = safeJson(productsRes);
  const products = Array.isArray(productsPayload) ? productsPayload : productsPayload?.products;
  const selectedProduct = pickProduct(products, productMode);

  const productSelected = check(selectedProduct, {
    'product selected': (product) => product !== null && Boolean(product.id),
  });

  if (!productSelected || !selectedProduct) {
    think(0.5, 1.0);
    return;
  }

  think(0.5, 1.0);

  const productId = selectedProduct.id;
  const productDetailRes = http.get(`${BASE_URL}/api/products/${productId}`, {
    headers,
    tags: { name: 'GET /api/products/:id', api: 'product-detail' },
  });

  const detailOk = check(productDetailRes, {
    'product detail status is 200 or 304': (res) => res.status === 200 || res.status === 304,
  });

  if (!detailOk || productDetailRes.status !== 200) {
    think(0.5, 1.0);
    return;
  }

  const productPayload = safeJson(productDetailRes);
  const product = productPayload?.product ?? productPayload;
  const selectedSize = pickSize(product);

  think(0.5, 1.5);

  const orderRes = http.post(
    `${BASE_URL}/api/orders`,
    JSON.stringify({
      items: [
        {
          productId,
          size: selectedSize,
          quantity: 1,
        },
      ],
    }),
    {
      headers,
      tags: { name: 'POST /api/orders', api: 'order-create' },
    },
  );

  const orderOk = check(orderRes, {
    'order status is 201': (res) => res.status === 201,
    'orderId exists': (res) => Boolean(safeJson(res, 'orderId')),
  });

  if (!orderOk || orderRes.status !== 201) {
    think(0.5, 1.0);
    return;
  }

  const orderId = safeJson(orderRes, 'orderId');
  if (!orderId) {
    think(0.5, 1.0);
    return;
  }

  think(0.5, 1.0);

  const paymentRes = http.post(
    `${BASE_URL}/api/payments`,
    JSON.stringify({
      orderId,
      method: Math.random() < 0.8 ? 'card' : 'bank',
    }),
    {
      headers,
      tags: { name: 'POST /api/payments', api: 'payment-create' },
    },
  );

  check(paymentRes, {
    'payment status is 200': (res) => res.status === 200,
    'paymentId exists': (res) => Boolean(safeJson(res, 'paymentId')),
    'payment has processed status': (res) => ['PAID', 'FAILED'].includes(String(safeJson(res, 'status'))),
  });

  think(0.5, 1.0);
}
