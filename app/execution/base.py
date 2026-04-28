from __future__ import annotations

from dataclasses import dataclass
from typing import Protocol


@dataclass(frozen=True)
class OrderLegRequest:
    leg_id: str
    family_id: str
    broker: str
    platform: str
    broker_symbol: str
    side: str
    order_type: str
    lots: str
    requested_entry: str | None
    sl_price: str | None
    tp_price: str | None
    magic: int
    comment: str


@dataclass(frozen=True)
class OrderLegReceipt:
    leg_id: str
    broker_ticket: str
    status: str
    actual_fill_price: str | None
    raw: dict


class ExecutionAdapter(Protocol):
    def open_legs(self, legs: list[OrderLegRequest]) -> list[OrderLegReceipt]:
        ...

    def modify_sl_tp(self, leg_ids: list[str], sl: str | None, tp: str | None) -> list[dict]:
        ...

    def close_legs(self, leg_ids: list[str]) -> list[dict]:
        ...

    def query_open_positions(self) -> list[dict]:
        ...
