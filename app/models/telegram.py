from __future__ import annotations

from sqlalchemy import BigInteger, Boolean, Column, DateTime, Index, Text, func
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import DeclarativeBase


class Base(DeclarativeBase):
    pass


class TelegramChat(Base):
    __tablename__ = "telegram_chats"

    chat_id = Column(BigInteger, primary_key=True)
    title = Column(Text, nullable=True)
    username = Column(Text, nullable=True)

    # Matches init migration schema
    provider_code = Column(Text, nullable=True)
    channel_kind = Column(Text, nullable=False, server_default="mixed")
    is_control_chat = Column(Boolean, nullable=False, server_default="false")

    created_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now())
    updated_at = Column(
        DateTime(timezone=True),
        nullable=False,
        server_default=func.now(),
        onupdate=func.now(),
    )

    __table_args__ = (
        Index("idx_telegram_chats_provider", "provider_code"),
        Index("ix_telegram_chats_username", "username"),
    )


class TelegramMessage(Base):
    __tablename__ = "telegram_messages"

    # Matches init migration schema (UUID PK generated in DB)
    msg_pk = Column(Text, primary_key=True)

    chat_id = Column(BigInteger, nullable=False)
    message_id = Column(BigInteger, nullable=False)

    sender_id = Column(BigInteger, nullable=True)
    sent_at = Column(DateTime(timezone=True), nullable=True)
    text = Column(Text, nullable=True)

    raw_json = Column(JSONB, nullable=False, server_default="'{}'::jsonb")

    is_edited = Column(Boolean, nullable=False, server_default="false")
    edited_at = Column(DateTime(timezone=True), nullable=True)

    created_at = Column(DateTime(timezone=True), nullable=False, server_default=func.now())

    __table_args__ = (
        Index("idx_telegram_messages_chat_time", "chat_id", "sent_at"),
    )
