from __future__ import annotations

from typing import Any, Literal

from pydantic import BaseModel, Field


class NodeHealthResponse(BaseModel):
    ok: bool
    node_name: str
    platform: Literal["mt4", "mt5", "stub"]
    broker: str
    terminal_connected: bool = False
    trading_enabled: bool = False
    detail: str = "ok"


class OpenLegRequestModel(BaseModel):
    leg_id: str
    family_id: str
    broker: str
    platform: str
    broker_symbol: str
    side: Literal["buy", "sell"]
    order_type: Literal["market", "limit", "stop"]
    lots: str
    requested_entry: str | None = None
    sl_price: str | None = None
    tp_price: str | None = None
    magic: int
    comment: str


class OpenLegsRequest(BaseModel):
    legs: list[OpenLegRequestModel]


class OpenLegReceiptModel(BaseModel):
    leg_id: str
    broker_ticket: str
    status: str = "open"
    actual_fill_price: str | None = None
    raw: dict[str, Any] = Field(default_factory=dict)


class OpenLegsResponse(BaseModel):
    receipts: list[OpenLegReceiptModel]


class ModifySlTpRequest(BaseModel):
    leg_ids: list[str]
    sl: str | None = None
    tp: str | None = None


class ActionResultModel(BaseModel):
    leg_id: str
    ok: bool
    status: str
    detail: str = "ok"
    raw: dict[str, Any] = Field(default_factory=dict)


class ModifySlTpResponse(BaseModel):
    results: list[ActionResultModel]


class CloseLegsRequest(BaseModel):
    leg_ids: list[str]


class CloseLegsResponse(BaseModel):
    results: list[ActionResultModel]


class OpenPositionModel(BaseModel):
    leg_id: str | None = None
    family_id: str | None = None
    broker_ticket: str
    broker_symbol: str
    side: Literal["buy", "sell"]
    lots: str
    open_price: str | None = None
    sl_price: str | None = None
    tp_price: str | None = None
    magic: int | None = None
    comment: str | None = None
    raw: dict[str, Any] = Field(default_factory=dict)


class OpenPositionsResponse(BaseModel):
    positions: list[OpenPositionModel]
