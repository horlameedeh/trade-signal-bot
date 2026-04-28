from __future__ import annotations

import requests

from app.execution.base import ExecutionAdapter, OrderLegReceipt, OrderLegRequest


class HttpExecutionNode(ExecutionAdapter):
    def __init__(self, base_url: str, timeout: float = 10.0):
        self.base_url = base_url.rstrip("/")
        self.timeout = timeout

    def open_legs(self, legs: list[OrderLegRequest]) -> list[OrderLegReceipt]:
        payload = {"legs": [leg.__dict__ for leg in legs]}
        r = requests.post(f"{self.base_url}/open-legs", json=payload, timeout=self.timeout)
        r.raise_for_status()
        data = r.json()

        return [
            OrderLegReceipt(
                leg_id=item["leg_id"],
                broker_ticket=str(item["broker_ticket"]),
                status=item.get("status", "open"),
                actual_fill_price=item.get("actual_fill_price"),
                raw=item,
            )
            for item in data.get("receipts", [])
        ]

    def modify_sl_tp(self, leg_ids: list[str], sl: str | None, tp: str | None) -> list[dict]:
        r = requests.post(
            f"{self.base_url}/modify-sl-tp",
            json={"leg_ids": leg_ids, "sl": sl, "tp": tp},
            timeout=self.timeout,
        )
        r.raise_for_status()
        return r.json().get("results", [])

    def close_legs(self, leg_ids: list[str]) -> list[dict]:
        r = requests.post(
            f"{self.base_url}/close-legs",
            json={"leg_ids": leg_ids},
            timeout=self.timeout,
        )
        r.raise_for_status()
        return r.json().get("results", [])

    def query_open_positions(self) -> list[dict]:
        r = requests.get(f"{self.base_url}/open-positions", timeout=self.timeout)
        r.raise_for_status()
        return r.json().get("positions", [])
