#!/bin/sh
set -eu

VUS="${VUS:-100}"
DURATION="${DURATION:-5m}"
BASE_URL="${BASE_URL:-http://msa_gateway:4000}"
PROMETHEUS_URL="${PROMETHEUS_URL:-http://shoply-prometheus:9090/api/v1/write}"
IMAGE="${IMAGE:-shoply-k6-loadtest:local}"
SLEEP_SECONDS="${SLEEP_SECONDS:-1}"
DOCKER_CONFIG="${DOCKER_CONFIG:-/Users/kyu/Projects/On_P_VS_AWS/msa_shoply/.docker-config}"
NETWORK="${NETWORK:-msa_shoply_default}"
RUN_ID="${RUN_ID:-$(date +%Y%m%d-%H%M%S)_vus-${VUS}_duration-${DURATION}}"
RESULTS_ROOT="${RESULTS_ROOT:-$(pwd)/load-test/results/order-payment}"
RESULT_DIR="${RESULT_DIR:-$RESULTS_ROOT/$RUN_ID}"

mkdir -p "$RESULT_DIR"

set +e
env DOCKER_CONFIG="$DOCKER_CONFIG" docker run --rm \
  --network "$NETWORK" \
  -v "$RESULT_DIR:/results" \
  -e BASE_URL="$BASE_URL" \
  -e VUS="$VUS" \
  -e DURATION="$DURATION" \
  -e SLEEP_SECONDS="$SLEEP_SECONDS" \
  -e TEST_RUN_ID="$RUN_ID" \
  -e K6_OUTPUT=experimental-prometheus-rw \
  -e K6_PROMETHEUS_RW_SERVER_URL="$PROMETHEUS_URL" \
  "$IMAGE"
EXIT_CODE=$?
set -e

echo "Saved k6 result files to: $RESULT_DIR"
exit "$EXIT_CODE"
