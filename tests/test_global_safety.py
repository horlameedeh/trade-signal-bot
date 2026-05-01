from pathlib import Path

from app.risk.global_safety import evaluate_global_safety


def _write_cfg(tmp_path, content: str) -> Path:
    p = tmp_path / "global_safety.yaml"
    p.write_text(content)
    return p


def test_kill_switch_blocks(tmp_path):
    cfg = _write_cfg(
        tmp_path,
        """
enabled: true
kill_switch:
  enabled: true
  reason: manual_stop
limits: {}
near_limit_threshold_pct: 80
""",
    )

    result = evaluate_global_safety(symbol="XAUUSD", path=cfg)

    assert result.decision == "block"
    assert "kill_switch_enabled:manual_stop" in result.reasons


def test_disabled_global_safety_allows(tmp_path):
    cfg = _write_cfg(
        tmp_path,
        """
enabled: false
kill_switch:
  enabled: true
  reason: ignored
limits: {}
near_limit_threshold_pct: 80
""",
    )

    result = evaluate_global_safety(symbol="XAUUSD", path=cfg)

    assert result.decision == "allow"
    assert result.reasons == ["global_safety_disabled"]


def test_empty_limits_allow(tmp_path):
    cfg = _write_cfg(
        tmp_path,
        """
enabled: true
kill_switch:
  enabled: false
limits: {}
near_limit_threshold_pct: 80
""",
    )

    result = evaluate_global_safety(symbol="XAUUSD", path=cfg)

    assert result.decision == "allow"
