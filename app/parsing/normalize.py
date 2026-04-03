from __future__ import annotations

import re
from typing import Iterable, Optional

_EMOJI_RE = re.compile(
    "["  # broad emoji ranges
    "\U0001F300-\U0001FAFF"
    "\U00002700-\U000027BF"
    "\U00002600-\U000026FF"
    "\U0001F1E6-\U0001F1FF"
    "]+",
    flags=re.UNICODE,
)

_WS_RE = re.compile(r"[ \t]+")

# Accept numbers with commas, decimals, optional parentheses
NUM_RE = re.compile(r"(?<!\w)(\(?-?\d{1,3}(?:,\d{3})*(?:\.\d+)?\)?|\(?-?\d+(?:\.\d+)?\)?)(?!\w)")


def strip_emoji(text: str) -> str:
    return _EMOJI_RE.sub("", text)


def normalize_ws(text: str) -> str:
    text = text.replace("\r\n", "\n").replace("\r", "\n")
    text = _WS_RE.sub(" ", text)
    return text.strip()


def clean_text(text: str) -> str:
    # keep line breaks for TP block detection; normalize spaces per line
    text = text.replace("\\n", "\n")
    text = strip_emoji(text)
    lines = [normalize_ws(x) for x in text.split("\n")]
    lines = [x for x in lines if x]
    return "\n".join(lines).strip()


def extract_numbers(text: str) -> list[str]:
    nums = []
    for m in NUM_RE.finditer(text):
        raw = m.group(1)
        # strip parentheses but keep numeric string integrity otherwise
        raw2 = raw.strip()
        if raw2.startswith("(") and raw2.endswith(")"):
            raw2 = raw2[1:-1].strip()
        nums.append(raw2)
    return nums


def first_number(text: str) -> Optional[str]:
    nums = extract_numbers(text)
    return nums[0] if nums else None


def split_csv_like(segment: str) -> list[str]:
    # split by commas / slashes / pipes but not decimals
    parts = re.split(r"[,\|/]+", segment)
    return [p.strip() for p in parts if p.strip()]


def preserve_tp_order(tp_candidates: Iterable[str]) -> list[str]:
    out: list[str] = []
    for x in tp_candidates:
        x = x.strip()
        if not x:
            continue
        out.append(x)
    return out
