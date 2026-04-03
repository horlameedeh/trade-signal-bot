# Milestone 5 Smoke Flow

Run commands from the repository root.

## Run variants

- Keep created rows (default):

```bash
PYTHONPATH=. python scripts/smoke_milestone5_flow.py
```

- Run and auto-clean created rows on success:

```bash
PYTHONPATH=. python scripts/smoke_milestone5_flow.py --auto-cleanup
```

- Force keep rows even if auto-cleanup flag is present:

```bash
PYTHONPATH=. python scripts/smoke_milestone5_flow.py --auto-cleanup --keep-data
```

## Manual cleanup

The smoke script prints a `source_msg_pk` at the end. Use it to clean only rows from that run:

```bash
PYTHONPATH=. python scripts/cleanup_milestone5_smoke.py <source_msg_pk> --execute
```

Optional dry-run (shows row counts only):

```bash
PYTHONPATH=. python scripts/cleanup_milestone5_smoke.py <source_msg_pk>
```
