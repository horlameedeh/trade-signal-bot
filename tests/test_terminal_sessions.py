from __future__ import annotations

from sqlalchemy import text

from app.db.session import SessionLocal


def test_terminal_sessions_table_exists() -> None:
    with SessionLocal() as db:
        exists = db.execute(
            text(
                """
                SELECT EXISTS (
                  SELECT 1
                  FROM information_schema.tables
                  WHERE table_schema = 'public'
                    AND table_name = 'terminal_sessions'
                )
                """
            )
        ).scalar()

    assert exists is True


def test_terminal_sessions_can_insert_and_close() -> None:
    with SessionLocal() as db:
        session_id = db.execute(
            text(
                """
                INSERT INTO terminal_sessions (terminal_name, meta)
                VALUES (:terminal_name, jsonb_build_object('source', 'pytest'))
                RETURNING session_id::text
                """
            ),
            {"terminal_name": "pytest-terminal-session"},
        ).scalar()
        db.commit()

        row = db.execute(
            text(
                """
                SELECT terminal_name, status, meta->>'source' AS source
                FROM terminal_sessions
                WHERE session_id = CAST(:session_id AS uuid)
                """
            ),
            {"session_id": session_id},
        ).mappings().first()

        assert row is not None
        assert row["terminal_name"] == "pytest-terminal-session"
        assert row["status"] == "active"
        assert row["source"] == "pytest"

        db.execute(
            text(
                """
                UPDATE terminal_sessions
                SET status = 'closed', ended_at = now()
                WHERE session_id = CAST(:session_id AS uuid)
                """
            ),
            {"session_id": session_id},
        )
        db.commit()

        closed = db.execute(
            text(
                """
                SELECT status, ended_at IS NOT NULL AS has_ended_at
                FROM terminal_sessions
                WHERE session_id = CAST(:session_id AS uuid)
                """
            ),
            {"session_id": session_id},
        ).mappings().first()

        db.execute(
            text(
                "DELETE FROM terminal_sessions WHERE session_id = CAST(:session_id AS uuid)"
            ),
            {"session_id": session_id},
        )
        db.commit()

    assert closed is not None
    assert closed["status"] == "closed"
    assert closed["has_ended_at"] is True