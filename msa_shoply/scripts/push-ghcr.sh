#!/bin/sh
set -eu

if [ -z "${GHCR_OWNER:-}" ]; then
  echo "GHCR_OWNER is required. Example: GHCR_OWNER=my-github-id IMAGE_TAG=latest $0"
  exit 1
fi

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
IMAGE_TAG="${IMAGE_TAG:-latest}"

SERVICES="
user
gateway
frontend
product
inventory
order
payment
"

echo "Building local Shoply images..."
docker compose -f "$ROOT_DIR/docker-compose.yml" build

for service in $SERVICES; do
  local_image="shoply-${service}:local"
  ghcr_image="ghcr.io/${GHCR_OWNER}/shoply-${service}:${IMAGE_TAG}"

  echo "Tagging $local_image -> $ghcr_image"
  docker tag "$local_image" "$ghcr_image"

  echo "Pushing $ghcr_image"
  docker push "$ghcr_image"
done

echo "Done."
echo "Use this on the target server:"
echo "GHCR_OWNER=$GHCR_OWNER IMAGE_TAG=$IMAGE_TAG docker compose -f docker-compose.ghcr.yml pull"
echo "GHCR_OWNER=$GHCR_OWNER IMAGE_TAG=$IMAGE_TAG docker compose -f docker-compose.ghcr.yml up -d"
