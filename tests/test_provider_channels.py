from app.services.provider_channels import (
    get_provider_channel,
    list_enabled_provider_channels,
    upsert_provider_channel,
)


def test_upsert_and_get_provider_channel():
    ch = upsert_provider_channel(
        provider_code="test_provider",
        chat_id=-100888000111,
        title="Test Provider",
        username="testprovider",
        is_enabled=True,
    )

    assert ch.provider_code == "test_provider"
    assert ch.chat_id == -100888000111

    loaded = get_provider_channel(chat_id=-100888000111)

    assert loaded is not None
    assert loaded.title == "Test Provider"
    assert loaded.username == "testprovider"


def test_list_enabled_provider_channels_excludes_disabled():
    upsert_provider_channel(
        provider_code="test_provider",
        chat_id=-100888000222,
        title="Enabled",
        is_enabled=True,
    )

    upsert_provider_channel(
        provider_code="test_provider",
        chat_id=-100888000333,
        title="Disabled",
        is_enabled=False,
    )

    channels = list_enabled_provider_channels()
    chat_ids = {c.chat_id for c in channels}

    assert -100888000222 in chat_ids
    assert -100888000333 not in chat_ids
def test_provider_channel_live_execution_defaults_false():
    ch = upsert_provider_channel(
        provider_code="test_live_controls",
        chat_id=-100889000111,
        title="Live Control Test",
        is_enabled=True,
    )

    assert ch.allow_live_execution is False


def test_provider_channel_can_enable_live_execution():
    ch = upsert_provider_channel(
        provider_code="test_live_controls",
        chat_id=-100889000222,
        title="Live Control Enabled",
        is_enabled=True,
        allow_live_execution=True,
        notes="test enabled",
    )

    assert ch.allow_live_execution is True
    assert ch.notes == "test enabled"
