# Milestone 28 Broker Owner Plan

## Pattern B — different users own different broker accounts

| Broker | Platform | Account label | Account ID | Intended slot | Intended prod name | Terminal name standard | Data dir standard | Status |
|---|---|---|---|---|---|---|---|---|
| ftmo | mt5 | FTMO - Execution | REPLACE_ACCOUNT_ID | user001 | TradeSignal User 001 | prod-ftmo-mt5-user001 | ~/Trading/Data/user001/ftmo-mt5 | planned |
| vantage | mt5 | Vantage - Execution | REPLACE_ACCOUNT_ID | user002 | TradeSignal User 002 | prod-vantage-mt5-user002 | ~/Trading/Data/user002/vantage-mt5 | planned |
| fundednext | mt5 | FundedNext - Execution | REPLACE_ACCOUNT_ID | user003 | TradeSignal User 003 | prod-fundednext-mt5-user003 | ~/Trading/Data/user003/fundednext-mt5 | planned |
| startrader | mt5 | StarTrader - Execution | REPLACE_ACCOUNT_ID | user004 | TradeSignal User 004 | prod-startrader-mt5-user004 | ~/Trading/Data/user004/startrader-mt5 | planned |
| bullwaves | mt5 | Bullwaves - Execution | REPLACE_ACCOUNT_ID | user005 | TradeSignal User 005 | prod-bullwaves-mt5-user005 | ~/Trading/Data/user005/bullwaves-mt5 | planned |
| traderscale | mt5 | Traderscale - Execution | REPLACE_ACCOUNT_ID | user001 | TradeSignal User 001 | prod-traderscale-mt5-user001 | ~/Trading/Data/user001/traderscale-mt5 | planned |

## Notes
- One broker account must map to exactly one user slot.
- broker_accounts.user_id becomes the DB source of truth.
- terminal_sessions.user_id must match broker_accounts.user_id.
- Terminal names must be unique and deterministic.
- Data directories must be isolated by user + broker + platform.
