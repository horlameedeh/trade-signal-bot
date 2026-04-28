#!/usr/bin/env bash
set -euo pipefail

export TRADEBOT_NODE_NAME="${TRADEBOT_NODE_NAME:-windows-node-stub}"
export TRADEBOT_NODE_BROKER="${TRADEBOT_NODE_BROKER:-vantage}"
export TRADEBOT_NODE_PLATFORM="${TRADEBOT_NODE_PLATFORM:-stub}"

python -m uvicorn app.execution.node_stub:app --host 0.0.0.0 --port "${TRADEBOT_NODE_PORT:-8008}"
