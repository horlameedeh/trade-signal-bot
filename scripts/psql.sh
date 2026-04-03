#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${DATABASE_URL:-}" ]]; then
  echo "DATABASE_URL is not set"
  exit 1
fi

PSQL_URL="${DATABASE_URL/+psycopg/}"
exec psql "$PSQL_URL" "$@"
