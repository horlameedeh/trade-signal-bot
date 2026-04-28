from __future__ import annotations

import os
import re
from dataclasses import dataclass
from typing import Any

from app.execution.node_contract import (
    ActionResultModel,
    OpenLegReceiptModel,
    OpenPositionModel,
)


@dataclass(frozen=True)
class Mt5Config:
    terminal_path: str | None
    live_enabled: bool
    deviation: int = 20


class Mt5Backend:
    def __init__(self, mt5_module: Any | None = None, config: Mt5Config | None = None):
        if mt5_module is None:
            import MetaTrader5 as mt5_module  # type: ignore

        self.mt5 = mt5_module
        self.config = config or Mt5Config(
            terminal_path=os.getenv("TRADEBOT_MT5_TERMINAL_PATH"),
            live_enabled=os.getenv("TRADEBOT_LIVE_TRADING_ENABLED", "false").lower() == "true",
            deviation=int(os.getenv("TRADEBOT_MT5_DEVIATION", "20")),
        )

    def initialize(self) -> bool:
        if self.config.terminal_path:
            return bool(self.mt5.initialize(path=self.config.terminal_path))
        return bool(self.mt5.initialize())

    def shutdown(self) -> None:
        try:
            self.mt5.shutdown()
        except Exception:
            pass

    def health(self) -> dict:
        initialized = self.initialize()
        info = self.mt5.terminal_info() if initialized else None
        account = self.mt5.account_info() if initialized else None

        return {
            "initialized": initialized,
            "terminal_connected": bool(info),
            "trading_enabled": bool(self.config.live_enabled and info and getattr(info, "trade_allowed", False)),
            "account_login": getattr(account, "login", None) if account else None,
            "server": getattr(account, "server", None) if account else None,
        }

    def _order_type(self, side: str, order_type: str) -> int:
        side = side.lower()
        order_type = order_type.lower()

        if order_type == "market":
            return self.mt5.ORDER_TYPE_BUY if side == "buy" else self.mt5.ORDER_TYPE_SELL

        if order_type == "limit":
            return self.mt5.ORDER_TYPE_BUY_LIMIT if side == "buy" else self.mt5.ORDER_TYPE_SELL_LIMIT

        if order_type == "stop":
            return self.mt5.ORDER_TYPE_BUY_STOP if side == "buy" else self.mt5.ORDER_TYPE_SELL_STOP

        raise ValueError(f"Unsupported order_type: {order_type}")

    def _trade_action(self, order_type: str) -> int:
        return self.mt5.TRADE_ACTION_DEAL if order_type.lower() == "market" else self.mt5.TRADE_ACTION_PENDING

    @staticmethod
    def _sanitize_comment(comment: str) -> str:
        """MT5 rejects comments with characters outside [A-Za-z0-9 _./-].
        Replace disallowed chars with '-' and truncate to 31 characters."""
        return re.sub(r"[^A-Za-z0-9 _./-]", "-", comment)[:31]

    def open_leg(self, leg) -> OpenLegReceiptModel:
        if not self.config.live_enabled:
            raise RuntimeError("MT5 live trading is disabled. Set TRADEBOT_LIVE_TRADING_ENABLED=true to enable.")

        if not self.initialize():
            raise RuntimeError(f"MT5 initialize failed: {self.mt5.last_error()}")

        symbol_info = self.mt5.symbol_info(leg.broker_symbol)
        if symbol_info is None:
            raise RuntimeError(f"MT5 symbol not found: {leg.broker_symbol}")

        if not symbol_info.visible:
            if not self.mt5.symbol_select(leg.broker_symbol, True):
                raise RuntimeError(f"MT5 symbol_select failed: {leg.broker_symbol}")

        tick = self.mt5.symbol_info_tick(leg.broker_symbol)
        if tick is None:
            raise RuntimeError(f"MT5 tick unavailable: {leg.broker_symbol}")

        order_type = self._order_type(leg.side, leg.order_type)
        action = self._trade_action(leg.order_type)

        if leg.order_type == "market":
            price = tick.ask if leg.side == "buy" else tick.bid
        else:
            price = float(leg.requested_entry)

        safe_comment = self._sanitize_comment(leg.comment)

        request = {
            "action": action,
            "symbol": leg.broker_symbol,
            "volume": float(leg.lots),
            "type": order_type,
            "price": price,
            "sl": float(leg.sl_price) if leg.sl_price is not None else 0.0,
            "tp": float(leg.tp_price) if leg.tp_price is not None else 0.0,
            "deviation": self.config.deviation,
            "magic": int(leg.magic),
            "comment": safe_comment,
            "type_time": self.mt5.ORDER_TIME_GTC,
            "type_filling": self.mt5.ORDER_FILLING_IOC,
        }

        result = self.mt5.order_send(request)
        if result is None:
            raise RuntimeError(f"MT5 order_send returned None: {self.mt5.last_error()}")

        retcode = getattr(result, "retcode", None)
        ok_retcode = getattr(self.mt5, "TRADE_RETCODE_DONE", 10009)
        placed_retcode = getattr(self.mt5, "TRADE_RETCODE_PLACED", 10008)

        if retcode not in {ok_retcode, placed_retcode}:
            raise RuntimeError(f"MT5 order_send failed retcode={retcode} result={result}")

        ticket = str(getattr(result, "order", None) or getattr(result, "deal", None))
        fill_price = str(getattr(result, "price", None) or price)

        return OpenLegReceiptModel(
            leg_id=leg.leg_id,
            broker_ticket=ticket,
            status="open",
            actual_fill_price=fill_price,
            raw={
                "retcode": retcode,
                "order": getattr(result, "order", None),
                "deal": getattr(result, "deal", None),
                "price": getattr(result, "price", None),
                "request": request,
            },
        )

    def modify_sl_tp(self, leg_id: str, ticket: str, symbol: str, sl: str | None, tp: str | None) -> ActionResultModel:
        if not self.config.live_enabled:
            raise RuntimeError("MT5 live trading is disabled.")

        if not self.initialize():
            raise RuntimeError(f"MT5 initialize failed: {self.mt5.last_error()}")

        request = {
            "action": self.mt5.TRADE_ACTION_SLTP,
            "position": int(ticket),
            "symbol": symbol,
            "sl": float(sl) if sl is not None else 0.0,
            "tp": float(tp) if tp is not None else 0.0,
        }

        result = self.mt5.order_send(request)
        retcode = getattr(result, "retcode", None)
        ok_retcode = getattr(self.mt5, "TRADE_RETCODE_DONE", 10009)

        return ActionResultModel(
            leg_id=leg_id,
            ok=retcode == ok_retcode,
            status="modified" if retcode == ok_retcode else "error",
            detail=f"retcode={retcode}",
            raw={"retcode": retcode, "request": request},
        )

    def close_leg(self, leg_id: str, ticket: str, symbol: str, side: str, lots: str) -> ActionResultModel:
        if not self.config.live_enabled:
            raise RuntimeError("MT5 live trading is disabled.")

        if not self.initialize():
            raise RuntimeError(f"MT5 initialize failed: {self.mt5.last_error()}")

        tick = self.mt5.symbol_info_tick(symbol)
        if tick is None:
            raise RuntimeError(f"MT5 tick unavailable: {symbol}")

        close_type = self.mt5.ORDER_TYPE_SELL if side == "buy" else self.mt5.ORDER_TYPE_BUY
        price = tick.bid if side == "buy" else tick.ask

        request = {
            "action": self.mt5.TRADE_ACTION_DEAL,
            "position": int(ticket),
            "symbol": symbol,
            "volume": float(lots),
            "type": close_type,
            "price": price,
            "deviation": self.config.deviation,
            "comment": self._sanitize_comment(f"tradebot-close:{leg_id}"),
        }

        result = self.mt5.order_send(request)
        retcode = getattr(result, "retcode", None)
        ok_retcode = getattr(self.mt5, "TRADE_RETCODE_DONE", 10009)

        return ActionResultModel(
            leg_id=leg_id,
            ok=retcode == ok_retcode,
            status="closed" if retcode == ok_retcode else "error",
            detail=f"retcode={retcode}",
            raw={"retcode": retcode, "request": request},
        )

    def open_positions(self) -> list[OpenPositionModel]:
        if not self.initialize():
            return []

        positions = self.mt5.positions_get() or []
        out: list[OpenPositionModel] = []

        for p in positions:
            comment = getattr(p, "comment", "") or ""
            leg_id = None
            family_id = None

            # Comment format on wire: "tradebot-{family_id}-{leg_id}" (colons
            # replaced with "-" to satisfy MT5 field constraints), or the
            # legacy "tradebot:{family_id}:{leg_id}" format on older positions.
            if comment.startswith("tradebot:"):
                parts = comment.split(":")
                if len(parts) >= 3:
                    family_id = parts[1]
                    leg_id = parts[2]
            elif comment.startswith("tradebot-") and comment.count("-") >= 2:
                # sanitized format: "tradebot-{family_id}-{leg_id}" (truncated)
                rest = comment[len("tradebot-"):]
                sep = rest.find("-")
                if sep != -1:
                    family_id = rest[:sep]
                    leg_id = rest[sep + 1:]

            side = "buy" if getattr(p, "type", 0) == self.mt5.ORDER_TYPE_BUY else "sell"

            out.append(
                OpenPositionModel(
                    leg_id=leg_id,
                    family_id=family_id,
                    broker_ticket=str(getattr(p, "ticket")),
                    broker_symbol=str(getattr(p, "symbol")),
                    side=side,
                    lots=str(getattr(p, "volume")),
                    open_price=str(getattr(p, "price_open", "")),
                    sl_price=str(getattr(p, "sl", "")),
                    tp_price=str(getattr(p, "tp", "")),
                    magic=getattr(p, "magic", None),
                    comment=comment,
                    raw={},
                )
            )

        return out
