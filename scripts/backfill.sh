#!/usr/bin/env bash
set -euo pipefail

export PYTHONPATH=.

# Example:
# ./scripts/backfill.sh --chat @fredtrading_signals --days 14
python -m app.ingest.backfill "$@"
