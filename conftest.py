"""Pytest configuration.

Ensures the repository root is importable so tests can import the `app` package
without requiring callers to set PYTHONPATH.
"""

from __future__ import annotations

import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))
