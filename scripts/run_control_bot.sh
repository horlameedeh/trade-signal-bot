#!/usr/bin/env bash
set -euo pipefail
PYTHONPATH=. python -m app.telegram.control_bot "$@"
