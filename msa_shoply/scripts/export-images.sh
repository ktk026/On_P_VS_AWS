#!/bin/sh
set -eu

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
RELEASE_DIR="$ROOT_DIR/release"
PACKAGE_DIR="$RELEASE_DIR/msa_shoply_release"
ARCHIVE_PATH="$RELEASE_DIR/msa_shoply_release.tar.gz"
IMAGE_TAR="$PACKAGE_DIR/shoply-images.tar"

IMAGES="
postgres:16-alpine
redis:7-alpine
shoply-user:local
shoply-gateway:local
shoply-frontend:local
shoply-product:local
shoply-inventory:local
shoply-order:local
shoply-payment:local
"

mkdir -p "$PACKAGE_DIR"

echo "Building Shoply service images..."
docker compose -f "$ROOT_DIR/docker-compose.yml" build

echo "Saving Docker images to $IMAGE_TAR..."
docker save -o "$IMAGE_TAR" $IMAGES

echo "Copying runtime files..."
cp "$ROOT_DIR/docker-compose.release.yml" "$PACKAGE_DIR/docker-compose.yml"
cp "$ROOT_DIR/.env.example" "$PACKAGE_DIR/.env.example"
cp "$ROOT_DIR/README.release.md" "$PACKAGE_DIR/README.md"

mkdir -p "$PACKAGE_DIR/db"
cp "$ROOT_DIR/db/schema.sql" "$PACKAGE_DIR/db/schema.sql"
cp "$ROOT_DIR/db/seed.sql" "$PACKAGE_DIR/db/seed.sql"

echo "Creating release archive..."
tar -czf "$ARCHIVE_PATH" -C "$RELEASE_DIR" msa_shoply_release

echo "Release package created:"
echo "$ARCHIVE_PATH"
