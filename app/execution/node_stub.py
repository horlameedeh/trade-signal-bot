from __future__ import annotations

import os
from concurrent.futures import ThreadPoolExecutor, TimeoutError as FuturesTimeoutError
from uuid import uuid4

from fastapi import FastAPI, HTTPException

from app.execution.node_contract import (
    ActionResultModel,
    CloseLegsRequest,
    CloseLegsResponse,
    TicketCloseRequest,
    TicketModifyRequest,
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
PLATFORM = os.getenv("TRADEBOT_NODE_PLATFORM", "stub").lower()

app = FastAPI(title="TradeBot Windows Execution Node")

_positions: dict[str, OpenPositionModel] = {}

HEALTH_TIMEOUT_SECONDS = float(os.getenv("TRADEBOT_NODE_HEALTH_TIMEOUT_SECONDS", "5"))
_health_executor = ThreadPoolExecutor(max_workers=1, thread_name_prefix="mt5-health")


def _mt5_backend():
    from app.execution.mt5_backend import Mt5Backend

    return Mt5Backend()


def _mt5_health_payload() -> dict:
    backend = _mt5_backend()
    return backend.health()


@app.get("/health", response_model=NodeHealthResponse)
def health() -> NodeHealthResponse:
    if PLATFORM == "mt5":
        future = _health_executor.submit(_mt5_health_payload)

        try:
            h = future.result(timeout=HEALTH_TIMEOUT_SECONDS)
            return NodeHealthResponse(
                ok=bool(h["initialized"]),
                node_name=NODE_NAME,
                platform="mt5",
                broker=BROKER,
                terminal_connected=bool(h["terminal_connected"]),
                trading_enabled=bool(h["trading_enabled"]),
                detail=f"account={h.get('account_login')} server={h.get('server')}",
            )
        except FuturesTimeoutError:
            return NodeHealthResponse(
                ok=False,
                node_name=NODE_NAME,
                platform="mt5",
                broker=BROKER,
                terminal_connected=False,
                trading_enabled=False,
                detail=f"MT5 health check timed out after {HEALTH_TIMEOUT_SECONDS:g}s",
            )
        except Exception as e:
            return NodeHealthResponse(
                ok=False,
                node_name=NODE_NAME,
                platform="mt5",
                broker=BROKER,
                terminal_connected=False,
                trading_enabled=False,
                detail=f"{type(e).__name__}: {str(e)}",
            )

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
    if PLATFORM == "mt5":
        try:
            backend = _mt5_backend()
            receipts = [backend.open_leg(leg) for leg in req.legs]
            return OpenLegsResponse(receipts=receipts)
        except Exception as e:
            import traceback
            error_detail = f"{type(e).__name__}: {str(e)}\n{traceback.format_exc()}"
            raise HTTPException(status_code=500, detail=error_detail)

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
    if PLATFORM == "mt5":
        raise HTTPException(status_code=501, detail="MT5 modify by leg_id requires DB ticket lookup in node or core-side routing")

    results: list[ActionResultModel] = []

    for leg_id in req.leg_ids:
        pos = _positions.get(leg_id)
        if not pos:
            results.append(ActionResultModel(leg_id=leg_id, ok=False, status="not_found", detail="position not found"))
            continue

        _positions[leg_id] = pos.model_copy(update={"sl_price": req.sl, "tp_price": req.tp})
        results.append(ActionResultModel(leg_id=leg_id, ok=True, status="modified", detail="sl/tp modified"))

    return ModifySlTpResponse(results=results)


@app.post("/close-legs", response_model=CloseLegsResponse)
def close_legs(req: CloseLegsRequest) -> CloseLegsResponse:
    if PLATFORM == "mt5":
        raise HTTPException(status_code=501, detail="MT5 close by leg_id requires DB ticket lookup in node or core-side routing")

    results: list[ActionResultModel] = []

    for leg_id in req.leg_ids:
        if leg_id in _positions:
            del _positions[leg_id]
            results.append(ActionResultModel(leg_id=leg_id, ok=True, status="closed", detail="position closed"))
        else:
            results.append(ActionResultModel(leg_id=leg_id, ok=False, status="not_found", detail="position not found"))

    return CloseLegsResponse(results=results)


@app.get("/open-positions", response_model=OpenPositionsResponse)
def open_positions() -> OpenPositionsResponse:
    if PLATFORM == "mt5":
        try:
            backend = _mt5_backend()
            return OpenPositionsResponse(positions=backend.open_positions())
        except Exception as e:
            import traceback
            error_detail = f"{type(e).__name__}: {str(e)}\n{traceback.format_exc()}"
            raise HTTPException(status_code=500, detail=error_detail)

    return OpenPositionsResponse(positions=list(_positions.values()))


@app.post("/modify-ticket-sl-tp", response_model=ModifySlTpResponse)
def modify_ticket_sl_tp(req: TicketModifyRequest) -> ModifySlTpResponse:
    if PLATFORM == "mt5":
        try:
            backend = _mt5_backend()
            results = [
                backend.modify_sl_tp(
                    leg_id=item.leg_id,
                    ticket=item.broker_ticket,
                    symbol=item.broker_symbol,
                    sl=item.sl,
                    tp=item.tp,
                )
                for item in req.tickets
            ]
            return ModifySlTpResponse(results=results)
        except Exception as e:
            raise HTTPException(status_code=500, detail=str(e))

    results: list[ActionResultModel] = []
    for item in req.tickets:
        pos = _positions.get(item.leg_id)
        if not pos:
            results.append(ActionResultModel(leg_id=item.leg_id, ok=False, status="not_found", detail="position not found"))
            continue
        _positions[item.leg_id] = pos.model_copy(update={"sl_price": item.sl, "tp_price": item.tp})
        results.append(ActionResultModel(leg_id=item.leg_id, ok=True, status="modified", detail="ticket sl/tp modified"))
    return ModifySlTpResponse(results=results)


@app.post("/close-tickets", response_model=CloseLegsResponse)
def close_tickets(req: TicketCloseRequest) -> CloseLegsResponse:
    if PLATFORM == "mt5":
        try:
            backend = _mt5_backend()
            results = [
                backend.close_leg(
                    leg_id=item.leg_id,
                    ticket=item.broker_ticket,
                    symbol=item.broker_symbol,
                    side=item.side,
                    lots=item.lots,
                )
                for item in req.tickets
            ]
            return CloseLegsResponse(results=results)
        except Exception as e:
            raise HTTPException(status_code=500, detail=str(e))

    results: list[ActionResultModel] = []
    for item in req.tickets:
        if item.leg_id in _positions:
            del _positions[item.leg_id]
            results.append(ActionResultModel(leg_id=item.leg_id, ok=True, status="closed", detail="ticket closed"))
        else:
            results.append(ActionResultModel(leg_id=item.leg_id, ok=False, status="not_found", detail="position not found"))
    return CloseLegsResponse(results=results)
