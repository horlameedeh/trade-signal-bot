from __future__ import annotations

import argparse

from sqlalchemy import text

from app.db.session import SessionLocal


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--account-id", required=True)
    parser.add_argument("--terminal-name", required=True)
    parser.add_argument("--terminal-path")
    parser.add_argument("--data-dir")
    parser.add_argument("--port", type=int)
    parser.add_argument(
        "--status",
        default="running",
        choices=["starting", "running", "stopped", "failed", "closed"],
    )
    args = parser.parse_args()

    params = {
        "account_id": args.account_id,
        "terminal_name": args.terminal_name,
        "terminal_path": args.terminal_path,
        "data_dir": args.data_dir,
        "port": args.port,
        "status": args.status,
    }

    with SessionLocal() as db:
        existing = db.execute(
            text(
                """
                SELECT session_id::text
                FROM terminal_sessions
                WHERE broker_account_id = CAST(:account_id AS uuid)
                  AND terminal_name = :terminal_name
                LIMIT 1
                """
            ),
            {
                "account_id": args.account_id,
                "terminal_name": args.terminal_name,
            },
        ).scalar()

        if existing:
            db.execute(
                text(
                    """
                    UPDATE terminal_sessions
                    SET terminal_path = :terminal_path,
                        data_dir = :data_dir,
                        port = :port,
                        status = :status,
                        last_heartbeat = now(),
                        updated_at = now(),
                        ended_at = CASE
                            WHEN :status IN ('stopped', 'failed', 'closed') THEN now()
                            ELSE NULL
                        END
                    WHERE session_id = CAST(:session_id AS uuid)
                    """
                ),
                params | {"session_id": existing},
            )
            db.commit()
            print(
                {
                    "updated": existing,
                    "terminal_name": args.terminal_name,
                    "status": args.status,
                }
            )
            return 0

        session_id = db.execute(
            text(
                """
                                INSERT INTO terminal_sessions (
                                    broker_account_id,
                                    terminal_name,
                                    terminal_path,
                                    data_dir,
                                    port,
                                    status,
                                    last_heartbeat,
                                    ended_at,
                                    meta
                                )
                                VALUES (
                                    CAST(:account_id AS uuid),
                                    :terminal_name,
                                    :terminal_path,
                                    :data_dir,
                                    :port,
                                    :status,
                                    now(),
                                    CASE
                                        WHEN :status IN ('stopped', 'failed', 'closed') THEN now()
                                        ELSE NULL
                                    END,
                                    '{}'::jsonb
                                )
                RETURNING session_id::text
                """
            ),
            params,
        ).scalar()
        db.commit()
        print(
            {
                "created": session_id,
                "terminal_name": args.terminal_name,
                "status": args.status,
            }
        )
        return 0


if __name__ == "__main__":
    raise SystemExit(main())