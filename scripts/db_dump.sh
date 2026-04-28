#!/usr/bin/env bash
set -e

OUTPUT=${1:-"db_snapshot.sql"}

docker compose exec -T postgres \
  pg_dump -U tradebot -d tradebot > "$OUTPUT"

echo "✅ Dump created: $OUTPUT"
