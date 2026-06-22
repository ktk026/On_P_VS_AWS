#!/bin/sh
set -eu

SCENARIO="${SCENARIO:-shoply-order-payment.js}"

if [ "$#" -gt 0 ]; then
  exec k6 "$@"
fi

if [ -n "${K6_OUTPUT:-}" ]; then
  exec k6 run -o "$K6_OUTPUT" "/scripts/$SCENARIO"
fi

exec k6 run "/scripts/$SCENARIO"
