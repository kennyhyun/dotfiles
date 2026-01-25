#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# .env 파일이 없으면 생성
if [ ! -f .env ]; then
  echo "Creating .env file from .env.example..."
  cp .env.example .env
  echo "Please edit .env file to configure your settings"
fi

# library 폴더 생성
mkdir -p library

echo "Starting Immich..."
docker compose up -d

echo ""
echo "Immich is starting up!"
echo "Access at: http://localhost:2283"
echo ""
echo "To view logs: docker compose logs -f"
echo "To stop: docker compose down"
