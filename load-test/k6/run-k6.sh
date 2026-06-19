#!/usr/bin/env bash
set -euo pipefail

SCENARIO="${1:-}"

if [ -z "$SCENARIO" ]; then
  echo "Usage: ./run-k6.sh [stable|spike|failover]"
  exit 1
fi

if [ ! -f .env ]; then
  echo ".env file not found."
  echo "Create it from k6.env.example, then update BASE_URL and PROMETHEUS_URL."
  exit 1
fi

set -a
# shellcheck disable=SC1091
source .env
set +a

case "$SCENARIO" in
  stable)
    SCRIPT="stable-flow.js"
    ;;
  spike)
    SCRIPT="spike-flow.js"
    ;;
  failover)
    SCRIPT="failover-flow.js"
    ;;
  *)
    echo "Unsupported scenario: $SCENARIO"
    echo "Available scenarios: stable, spike, failover"
    exit 1
    ;;
esac

if [ ! -d scripts ]; then
  echo "scripts directory not found. Run this script from the k6 folder."
  exit 1
fi

if [ ! -f "scripts/$SCRIPT" ]; then
  echo "Scenario file not found: scripts/$SCRIPT"
  exit 1
fi

: "${BASE_URL:?BASE_URL is required in .env}"
: "${PROMETHEUS_URL:?PROMETHEUS_URL is required in .env}"
: "${ACCOUNT_COUNT:=2000}"
: "${TEST_PASSWORD:=Test1234!}"
: "${K6_PROMETHEUS_RW_TREND_STATS:=p(50),p(90),p(95),p(99)}"

echo "======================================"
echo "Shoply k6 Load Test"
echo "Scenario: $SCENARIO"
echo "Script: $SCRIPT"
echo "Target: $BASE_URL"
echo "Prometheus: $PROMETHEUS_URL"
echo "Account count: $ACCOUNT_COUNT"
echo "======================================"

docker run --rm --network host \
  -e BASE_URL="$BASE_URL" \
  -e K6_PROMETHEUS_RW_SERVER_URL="$PROMETHEUS_URL" \
  -e ACCOUNT_COUNT="$ACCOUNT_COUNT" \
  -e TEST_PASSWORD="$TEST_PASSWORD" \
  -e K6_PROMETHEUS_RW_TREND_STATS="$K6_PROMETHEUS_RW_TREND_STATS" \
  -v "$PWD/scripts:/scripts" \
  grafana/k6 run -o experimental-prometheus-rw "/scripts/$SCRIPT"
