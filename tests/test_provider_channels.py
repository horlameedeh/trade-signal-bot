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
