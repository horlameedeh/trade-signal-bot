from __future__ import annotations

import os
from uuid import uuid4

from fastapi import FastAPI

from app.execution.node_contract import (
    ActionResultModel,
    CloseLegsRequest,
    CloseLegsResponse,
    ModifySlTpRequest,
    ModifySlTpResponse,
    NodeHealthResponse,
    OpenLegReceiptModel,
    OpenLegsRequest,
    OpenLegsResponse,
    OpenPositionModel,
    OpenPositionsResponse,
)

NODE_NAME = os.getenv("TRADEBOT_NODE_NAME", "windows-node-stub")
BROKER = os.getenv("TRADEBOT_NODE_BROKER", "vantage")
PLATFORM = os.getenv("TRADEBOT_NODE_PLATFORM", "stub")

app = FastAPI(title="TradeBot Windows Execution Node Stub")

_positions: dict[str, OpenPositionModel] = {}


@app.get("/health", response_model=NodeHealthResponse)
def health() -> NodeHealthResponse:
    return NodeHealthResponse(
        ok=True,
        node_name=NODE_NAME,
        platform="stub",
        broker=BROKER,
        terminal_connected=False,
        trading_enabled=False,
        detail="stub node healthy",
    )


@app.post("/open-legs", response_model=OpenLegsResponse)
def open_legs(req: OpenLegsRequest) -> OpenLegsResponse:
    receipts: list[OpenLegReceiptModel] = []

    for leg in req.legs:
        ticket = f"STUB-{uuid4().hex[:12]}"
        fill = leg.requested_entry

        _positions[leg.leg_id] = OpenPositionModel(
            leg_id=leg.leg_id,
            family_id=leg.family_id,
            broker_ticket=ticket,
            broker_symbol=leg.broker_symbol,
            side=leg.side,
            lots=leg.lots,
            open_price=fill,
            sl_price=leg.sl_price,
            tp_price=leg.tp_price,
            magic=leg.magic,
            comment=leg.comment,
            raw={"stub": True},
        )

        receipts.append(
            OpenLegReceiptModel(
                leg_id=leg.leg_id,
                broker_ticket=ticket,
                status="open",
                actual_fill_price=fill,
                raw={"stub": True, "comment": leg.comment},
            )
        )

    return OpenLegsResponse(receipts=receipts)


@app.post("/modify-sl-tp", response_model=ModifySlTpResponse)
def modify_sl_tp(req: ModifySlTpRequest) -> ModifySlTpResponse:
    results: list[ActionResultModel] = []

    for leg_id in req.leg_ids:
        pos = _positions.get(leg_id)
        if not pos:
            results.append(
                ActionResultModel(
                    leg_id=leg_id,
                    ok=False,
                    status="not_found",
                    detail="position not found",
                )
            )
            continue

        updated = pos.model_copy(update={"sl_price": req.sl, "tp_price": req.tp})
        _positions[leg_id] = updated

        results.append(
            ActionResultModel(
                leg_id=leg_id,
                ok=True,
                status="modified",
                detail="sl/tp modified",
            )
        )

    return ModifySlTpResponse(results=results)


@app.post("/close-legs", response_model=CloseLegsResponse)
def close_legs(req: CloseLegsRequest) -> CloseLegsResponse:
    results: list[ActionResultModel] = []

    for leg_id in req.leg_ids:
        if leg_id in _positions:
            del _positions[leg_id]
            results.append(
                ActionResultModel(
                    leg_id=leg_id,
                    ok=True,
                    status="closed",
                    detail="position closed",
                )
            )
        else:
            results.append(
                ActionResultModel(
                    leg_id=leg_id,
                    ok=False,
                    status="not_found",
                    detail="position not found",
                )
            )

    return CloseLegsResponse(results=results)


@app.get("/open-positions", response_model=OpenPositionsResponse)
def open_positions() -> OpenPositionsResponse:
    return OpenPositionsResponse(positions=list(_positions.values()))
