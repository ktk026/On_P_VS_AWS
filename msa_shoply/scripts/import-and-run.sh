#!/bin/sh
set -eu

if [ ! -f shoply-images.tar ]; then
  echo "shoply-images.tar not found. Run this script inside the extracted release folder."
  exit 1
fi

if [ ! -f .env ]; then
  cp .env.example .env
fi

echo "Loading Shoply Docker images..."
docker load -i shoply-images.tar

echo "Starting Shoply..."
docker compose up -d

echo "Shoply is starting."
echo "Frontend: http://localhost:3000"
echo "Gateway:  http://localhost:4000"
