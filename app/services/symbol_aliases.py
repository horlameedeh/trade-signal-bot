from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Optional

import yaml


DEFAULT_SYMBOL_MAP_PATH = Path("config/symbol_maps.yaml")


@dataclass(frozen=True)
class SymbolResolutionResult:
    canonical_symbol: str
    broker: str
    platform: str
    resolved_symbol: Optional[str]
    found: bool
    blocked: bool
    reason: str


def _load_maps(path: Path = DEFAULT_SYMBOL_MAP_PATH) -> dict:
    with path.open("r", encoding="utf-8") as f:
        return yaml.safe_load(f)


def resolve_broker_symbol(
    *,
    canonical_symbol: str,
    broker: str,
    platform: str,
    path: Path = DEFAULT_SYMBOL_MAP_PATH,
) -> SymbolResolutionResult:
    canonical = canonical_symbol.upper()
    broker_key = broker.lower()
    platform_key = platform.lower()

    data = _load_maps(path)
    brokers = data.get("brokers", {})

    if broker_key not in brokers:
        return SymbolResolutionResult(
            canonical_symbol=canonical,
            broker=broker_key,
            platform=platform_key,
            resolved_symbol=None,
            found=False,
            blocked=True,
            reason="unknown_broker_profile",
        )

    broker_map = brokers[broker_key]
    if platform_key not in broker_map:
        return SymbolResolutionResult(
            canonical_symbol=canonical,
            broker=broker_key,
            platform=platform_key,
            resolved_symbol=None,
            found=False,
            blocked=True,
            reason="unknown_platform_profile",
        )

    platform_map = broker_map[platform_key]
    resolved = platform_map.get(canonical)

    if not resolved:
        return SymbolResolutionResult(
            canonical_symbol=canonical,
            broker=broker_key,
            platform=platform_key,
            resolved_symbol=None,
            found=False,
            blocked=True,
            reason="missing_symbol_mapping",
        )

    return SymbolResolutionResult(
        canonical_symbol=canonical,
        broker=broker_key,
        platform=platform_key,
        resolved_symbol=str(resolved),
        found=True,
        blocked=False,
        reason="ok",
    )
