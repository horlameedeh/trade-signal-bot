#!/usr/bin/env bash
set -euo pipefail

export PYTHONPATH=.

python -m app.ingest.listener
