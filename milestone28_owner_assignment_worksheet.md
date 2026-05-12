# Milestone 28B Owner Assignment Worksheet

## Slot policy

| slot | prod_name | slot_category | primary_broker_plan | secondary_broker_plan | status | notes |
|---|---|---|---|---|---|---|
| user001 | TradeSignal User 001 | live+prop | vantage mt5 | ftmo mt5 | claim-ready | preferred first claimant |
| user002 | TradeSignal User 002 | live+prop | startrader mt5 | fundednext mt5 | claim-ready | preferred second claimant |
| user003 | TradeSignal User 003 | live+prop | bullwaves mt5 | traderscale mt5 | partially blocked | bullwaves blocked until terminal exe exists |
| user004 | TradeSignal User 004 | prop reserve | traderscale mt5 reserve | none | reserve | assign when real claimant arrives |
| user005 | TradeSignal User 005 | prop reserve | fundednext/ftmo reserve | none | reserve | assign when real claimant arrives |

## Broker readiness

| broker | category | platform | binary_folder | terminal_exe_status | recommended_state |
|---|---|---|---|---|---|
| vantage | live | mt5 | C:\Trading\Binaries\Vantage_MT5 | ready | claim-ready |
| startrader | live | mt5 | C:\Trading\Binaries\StarTrader_MT5 | ready | claim-ready |
| bullwaves | live | mt5 | C:\Trading\Binaries\Bullwaves_MT5 | missing | blocked |
| ftmo | prop | mt5 | C:\Trading\Binaries\FTMO_MT5 | ready | claim-ready |
| traderscale | prop | mt5 | C:\Trading\Binaries\Traderscale_MT5 | ready | claim-ready |
| fundednext | prop | mt5 | C:\Trading\Binaries\FundedNext_MT5 | ready | claim-ready |

## Claim rules

- Do not pre-register dormant terminal sessions in the DB.
- A slot claim happens before terminal registration.
- broker_accounts.user_id must be assigned before live routing is trusted.
- terminal_sessions.user_id must match broker_accounts.user_id.
- One slot should hold at most one live broker initially.
- Optional second broker should be prop-only until operations are stable.
- admin remains operator, not long-term tenant owner.
