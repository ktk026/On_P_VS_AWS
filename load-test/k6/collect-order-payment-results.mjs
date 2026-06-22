import { readdir, readFile, writeFile } from 'node:fs/promises';
import path from 'node:path';

const root = process.env.RESULTS_ROOT || path.resolve('load-test/results/order-payment');
const csvPath = process.env.CSV_PATH || path.join(root, 'order-payment-summary.csv');
const markdownPath = process.env.MARKDOWN_PATH || path.join(root, 'order-payment-summary.md');

function value(summary, key) {
  return summary.metrics?.[key] ?? '';
}

function percent(raw) {
  if (raw === '' || raw === null || raw === undefined) return '';
  return (Number(raw) * 100).toFixed(2);
}

function number(raw, digits = 2) {
  if (raw === '' || raw === null || raw === undefined) return '';
  return Number(raw).toFixed(digits);
}

function csvCell(raw) {
  const text = String(raw ?? '');
  return `"${text.replaceAll('"', '""')}"`;
}

const entries = await readdir(root, { withFileTypes: true }).catch(() => []);
const summaries = [];

for (const entry of entries) {
  if (!entry.isDirectory()) continue;

  const summaryPath = path.join(root, entry.name, 'summary.json');
  try {
    const summary = JSON.parse(await readFile(summaryPath, 'utf8'));
    summaries.push(summary);
  } catch {
    // Skip incomplete or unrelated result directories.
  }
}

summaries.sort((a, b) => String(a.startedAt).localeCompare(String(b.startedAt)));

const rows = summaries.map((summary) => ({
  runId: summary.runId,
  startedAt: summary.startedAt,
  baseUrl: summary.baseUrl,
  vus: summary.vus,
  duration: summary.duration,
  httpReqs: value(summary, 'httpReqs'),
  httpReqRate: number(value(summary, 'httpReqRate')),
  httpFailedRatePct: percent(value(summary, 'httpReqFailedRate')),
  httpDurationP95Ms: number(value(summary, 'httpReqDurationP95Ms')),
  iterations: value(summary, 'iterations'),
  iterationRate: number(value(summary, 'iterationRate')),
  orderAttempts: value(summary, 'orderAttempts'),
  orderCreatedRatePct: percent(value(summary, 'orderCreatedRate')),
  paymentAttempts: value(summary, 'paymentAttempts'),
  paymentProcessedRatePct: percent(value(summary, 'paymentProcessedRate')),
  checksSucceededRatePct: percent(value(summary, 'checksSucceededRate')),
}));

const headers = [
  'runId',
  'startedAt',
  'baseUrl',
  'vus',
  'duration',
  'httpReqs',
  'httpReqRate',
  'httpFailedRatePct',
  'httpDurationP95Ms',
  'iterations',
  'iterationRate',
  'orderAttempts',
  'orderCreatedRatePct',
  'paymentAttempts',
  'paymentProcessedRatePct',
  'checksSucceededRatePct',
];

const csv = [
  headers.join(','),
  ...rows.map((row) => headers.map((header) => csvCell(row[header])).join(',')),
].join('\n');

const markdown = [
  '# Shoply Order Payment Result Summary',
  '',
  '| Run ID | VUs | Duration | HTTP Failed % | p95 ms | Order Created % | Payment Processed % | Req/s |',
  '|---|---:|---:|---:|---:|---:|---:|---:|',
  ...rows.map((row) => (
    `| ${row.runId} | ${row.vus} | ${row.duration} | ${row.httpFailedRatePct} | ${row.httpDurationP95Ms} | ${row.orderCreatedRatePct} | ${row.paymentProcessedRatePct} | ${row.httpReqRate} |`
  )),
  '',
].join('\n');

await writeFile(csvPath, `${csv}\n`);
await writeFile(markdownPath, markdown);

console.log(`Collected ${rows.length} result(s).`);
console.log(`CSV: ${csvPath}`);
console.log(`Markdown: ${markdownPath}`);
