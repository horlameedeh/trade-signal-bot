#!/usr/bin/env bash
set -e

OUTPUT=${1:-"db_schema.sql"}

docker compose exec -T postgres \
  pg_dump -U tradebot -d tradebot --schema-only > "$OUTPUT"

echo "✅ Schema dump created: $OUTPUT"
