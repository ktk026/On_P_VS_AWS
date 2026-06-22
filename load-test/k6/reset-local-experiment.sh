#!/bin/sh
set -eu

DOCKER_CONFIG="${DOCKER_CONFIG:-/Users/kyu/Projects/On_P_VS_AWS/msa_shoply/.docker-config}"

docker exec -i msa_postgres psql -U shoply -d shoply <<'SQL'
TRUNCATE payments, order_items, orders RESTART IDENTITY CASCADE;
UPDATE inventory SET reserved = 0;
UPDATE products
SET is_timesale = FALSE, sale_price = NULL, sale_ends_at = NULL;
SQL

docker exec msa_redis redis-cli FLUSHALL >/dev/null

DOCKER_CONFIG="$DOCKER_CONFIG" docker compose -f /Users/kyu/Projects/On_P_VS_AWS/msa_shoply/docker-compose.yml restart \
  product inventory order payment gateway >/dev/null

echo "Shoply local experiment state reset."
