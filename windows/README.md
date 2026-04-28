# TradeBot Windows Execution Node

This folder contains the Windows deployment package for the Trade Signal Bot execution node.

For now, this runs the FastAPI stub node. Later, the same service wrapper will host the MT4/MT5-backed execution node.

## Recommended Windows PC setup

Install:

- Windows 11 Pro
- Python 3.11+
- Git
- MT4 terminals as needed
- MT5 terminals as needed
- NSSM for service installation

Do not install MT4/MT5 terminals inside `Program Files`.

Recommended structure:

```text
C:\Trading\
  Vantage_MT5\
  Vantage_MT4\
  FTMO_MT5\
  FTMO_MT4\

C:\trade-signal-bot\
C:\Tools\nssm\