import http from 'k6/http';
import { check, sleep } from 'k6';
import { Counter, Rate } from 'k6/metrics';

import { BASE_URL, DEFAULT_HEADERS } from './config.js';

export const options = {
  vus: Number(__ENV.VUS || 100),
  duration: __ENV.DURATION || '5m',
  thresholds: {
    http_req_failed: ['rate<0.10'],
    http_req_duration: ['p(95)<2000'],
    order_created: ['rate>0.90'],
    payment_processed: ['rate>0.90'],
  },
};

const sizes = [240, 250, 260, 270, 280, 290, 300];

export const orderCreated = new Rate('order_created');
export const paymentProcessed = new Rate('payment_processed');
export const orderAttempts = new Counter('order_attempts');
export const paymentAttempts = new Counter('payment_attempts');

function metricValue(data, name, key) {
  return data.metrics[name]?.values?.[key] ?? null;
}

function percent(value) {
  return value === null ? 'n/a' : `${(value * 100).toFixed(2)}%`;
}

function numberValue(value, digits = 2) {
  return value === null ? 'n/a' : Number(value).toFixed(digits);
}

function countValue(value) {
  return value === null ? 'n/a' : String(Math.round(Number(value)));
}

export function setup() {
  const res = http.get(`${BASE_URL}/api/products`, {
    tags: { name: 'GET /api/products setup', flow: 'setup' },
  });

  if (res.status !== 200) {
    throw new Error(`Failed to load products: HTTP ${res.status}`);
  }

  const products = res.json();
  if (!Array.isArray(products) || products.length === 0) {
    throw new Error('No products returned from /api/products');
  }

  return {
    products: products.map((p) => ({
      id: p.id,
      name: p.name,
    })),
  };
}

function randomItem(items) {
  return items[Math.floor(Math.random() * items.length)];
}

export default function (data) {
  const product = randomItem(data.products);
  const size = randomItem(sizes);
  const quantity = 1;

  orderAttempts.add(1);

  const orderRes = http.post(
    `${BASE_URL}/api/orders`,
    JSON.stringify({
      items: [
        {
          productId: product.id,
          size,
          quantity,
        },
      ],
    }),
    {
      headers: DEFAULT_HEADERS,
      tags: { name: 'POST /api/orders', flow: 'order_payment' },
    },
  );

  const orderOk = check(orderRes, {
    'order created': (r) => r.status === 201,
    'order has orderId': (r) => r.status === 201 && Boolean(r.json('orderId')),
  });
  orderCreated.add(orderOk);

  if (!orderOk) {
    sleep(Number(__ENV.SLEEP_SECONDS || 1));
    return;
  }

  const orderId = orderRes.json('orderId');
  paymentAttempts.add(1);

  const paymentRes = http.post(
    `${BASE_URL}/api/payments`,
    JSON.stringify({
      orderId,
      method: Math.random() < 0.8 ? 'card' : 'bank',
    }),
    {
      headers: DEFAULT_HEADERS,
      tags: { name: 'POST /api/payments', flow: 'order_payment' },
    },
  );

  const paymentOk = check(paymentRes, {
    'payment processed': (r) => r.status === 200,
    'payment has status': (r) => r.status === 200 && ['PAID', 'FAILED'].includes(String(r.json('status'))),
  });
  paymentProcessed.add(paymentOk);

  sleep(Number(__ENV.SLEEP_SECONDS || 1));
}

export function handleSummary(data) {
  const runId = __ENV.TEST_RUN_ID || new Date().toISOString();
  const startedAt = new Date().toISOString();
  const summary = {
    runId,
    startedAt,
    scenario: 'shoply-order-payment',
    baseUrl: BASE_URL,
    vus: Number(__ENV.VUS || 100),
    duration: __ENV.DURATION || '5m',
    sleepSeconds: Number(__ENV.SLEEP_SECONDS || 1),
    thresholds: data.root_group?.checks || {},
    metrics: {
      httpReqs: metricValue(data, 'http_reqs', 'count'),
      httpReqRate: metricValue(data, 'http_reqs', 'rate'),
      httpReqFailedRate: metricValue(data, 'http_req_failed', 'rate'),
      httpReqDurationAvgMs: metricValue(data, 'http_req_duration', 'avg'),
      httpReqDurationP90Ms: metricValue(data, 'http_req_duration', 'p(90)'),
      httpReqDurationP95Ms: metricValue(data, 'http_req_duration', 'p(95)'),
      iterations: metricValue(data, 'iterations', 'count'),
      iterationRate: metricValue(data, 'iterations', 'rate'),
      orderAttempts: metricValue(data, 'order_attempts', 'count'),
      orderCreatedRate: metricValue(data, 'order_created', 'rate'),
      paymentAttempts: metricValue(data, 'payment_attempts', 'count'),
      paymentProcessedRate: metricValue(data, 'payment_processed', 'rate'),
      checksSucceededRate: metricValue(data, 'checks', 'rate'),
    },
    raw: data,
  };

  const markdown = `# Shoply Order Payment Load Test

| Field | Value |
|---|---:|
| Run ID | ${runId} |
| Started At | ${startedAt} |
| Base URL | ${BASE_URL} |
| VUs | ${summary.vus} |
| Duration | ${summary.duration} |
| Sleep Seconds | ${summary.sleepSeconds} |

## Result

| Metric | Value |
|---|---:|
| HTTP Requests | ${countValue(summary.metrics.httpReqs)} |
| HTTP Request Rate | ${numberValue(summary.metrics.httpReqRate)} /s |
| HTTP Failed Rate | ${percent(summary.metrics.httpReqFailedRate)} |
| HTTP Duration p90 | ${numberValue(summary.metrics.httpReqDurationP90Ms)} ms |
| HTTP Duration p95 | ${numberValue(summary.metrics.httpReqDurationP95Ms)} ms |
| Iterations | ${countValue(summary.metrics.iterations)} |
| Iteration Rate | ${numberValue(summary.metrics.iterationRate)} /s |
| Order Attempts | ${countValue(summary.metrics.orderAttempts)} |
| Order Created Rate | ${percent(summary.metrics.orderCreatedRate)} |
| Payment Attempts | ${countValue(summary.metrics.paymentAttempts)} |
| Payment Processed Rate | ${percent(summary.metrics.paymentProcessedRate)} |
| Checks Succeeded Rate | ${percent(summary.metrics.checksSucceededRate)} |
`;

  return {
    stdout: markdown,
    '/results/summary.json': JSON.stringify(summary, null, 2),
    '/results/summary.md': markdown,
  };
}
