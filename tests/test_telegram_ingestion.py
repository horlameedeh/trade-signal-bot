from pathlib import Path

from app.telegram.ingestion import load_signal_channels


def test_load_signal_channels(tmp_path):
    cfg = tmp_path / "signal_channels.yaml"
    cfg.write_text(
        """
enabled: true
dry_run: true
channels:
  - provider: fredtrading
    chat_id: -100123
    label: Fred
    enabled: true
  - provider: ignored
    chat_id: -100999
    enabled: false
""",
        encoding="utf-8",
    )

    enabled, dry_run, channels = load_signal_channels(cfg)

    assert enabled is True
    assert dry_run is True
    assert len(channels) == 1
    assert channels[0].provider == "fredtrading"
    assert channels[0].chat_id == -100123
