#!/usr/bin/env python3
"""SWE40006 Task 4.4 - Expense report processor (non-web container).

Batch job: reads expense CSV files from an input folder, validates each row,
aggregates totals by category and month, and writes a CSV + JSON report.

Storage used inside the container:
  /data/input   host bind mount (read-only)  - CSV files to process
  /data/output  host bind mount              - generated reports
  /data/state   named Docker volume          - SQLite run history

The state volume lets the job remember which files it has already processed,
so a second run with the same inputs skips them. That is how persistence is
demonstrated across container lifecycles.
"""
import argparse
import csv
import hashlib
import json
import logging
import os
import sqlite3
import sys
from collections import defaultdict
from datetime import datetime, timezone
from pathlib import Path

REQUIRED_COLUMNS = {"date", "category", "description", "amount"}

log = logging.getLogger("processor")


def parse_args():
    p = argparse.ArgumentParser(description="Summarise expense CSV files.")
    p.add_argument("--input", default=os.getenv("INPUT_DIR", "/data/input"))
    p.add_argument("--output", default=os.getenv("OUTPUT_DIR", "/data/output"))
    p.add_argument("--state", default=os.getenv("STATE_DIR", "/data/state"))
    p.add_argument("--currency", default=os.getenv("CURRENCY", "AUD"))
    p.add_argument("--reprocess", action="store_true",
                   help="process files even if they were seen in an earlier run")
    p.add_argument("--history", action="store_true",
                   help="print previous runs from the state volume and exit")
    return p.parse_args()


def open_state(state_dir: Path) -> sqlite3.Connection:
    state_dir.mkdir(parents=True, exist_ok=True)
    db = sqlite3.connect(state_dir / "history.db")
    db.execute("""CREATE TABLE IF NOT EXISTS runs (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        started_at TEXT, finished_at TEXT, host TEXT,
        files_processed INTEGER, rows_ok INTEGER, rows_rejected INTEGER,
        total REAL, report TEXT)""")
    db.execute("""CREATE TABLE IF NOT EXISTS processed_files (
        sha256 TEXT PRIMARY KEY, filename TEXT, run_id INTEGER)""")
    db.commit()
    return db


def file_hash(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def read_rows(path: Path):
    """Yield (row_number, cleaned_row) and log rejected rows."""
    with path.open(newline="", encoding="utf-8") as fh:
        reader = csv.DictReader(fh)
        missing = REQUIRED_COLUMNS - set(reader.fieldnames or [])
        if missing:
            raise ValueError(f"{path.name}: missing columns {sorted(missing)}")
        for n, row in enumerate(reader, start=2):
            try:
                date = datetime.strptime(row["date"].strip(), "%Y-%m-%d")
                amount = round(float(row["amount"]), 2)
                if amount < 0:
                    raise ValueError("negative amount")
                category = row["category"].strip().title() or "Uncategorised"
                yield n, {"date": date, "category": category,
                          "description": row["description"].strip(),
                          "amount": amount}
            except (ValueError, KeyError) as exc:
                log.warning("REJECT %s line %d: %s -> %s", path.name, n, dict(row), exc)
                yield n, None


def main() -> int:
    args = parse_args()
    logging.basicConfig(level=os.getenv("LOG_LEVEL", "INFO"),
                        format="%(asctime)s [%(levelname)s] %(message)s",
                        datefmt="%Y-%m-%d %H:%M:%S", stream=sys.stdout)

    in_dir, out_dir, state_dir = Path(args.input), Path(args.output), Path(args.state)
    db = open_state(state_dir)

    if args.history:
        rows = db.execute("SELECT id, started_at, host, files_processed, rows_ok, "
                          "rows_rejected, total, report FROM runs ORDER BY id").fetchall()
        log.info("Run history (%d runs) from %s/history.db", len(rows), state_dir)
        for r in rows:
            log.info("run #%d | %s | host=%s | files=%d ok=%d rejected=%d | total=%.2f | %s", *r)
        return 0

    started = datetime.now(timezone.utc)
    host = os.uname().nodename
    log.info("Container %s starting expense processor", host)
    log.info("input=%s output=%s state=%s currency=%s", in_dir, out_dir, state_dir, args.currency)

    if not in_dir.is_dir():
        log.error("Input folder %s does not exist - is the bind mount configured?", in_dir)
        return 1

    csv_files = sorted(in_dir.glob("*.csv"))
    log.info("Found %d CSV file(s): %s", len(csv_files), [f.name for f in csv_files])

    by_category = defaultdict(float)
    by_month = defaultdict(float)
    rows_ok = rows_rejected = 0
    new_files = []

    for path in csv_files:
        digest = file_hash(path)
        seen = db.execute("SELECT run_id FROM processed_files WHERE sha256=?", (digest,)).fetchone()
        if seen and not args.reprocess:
            log.info("SKIP %s (already processed in run #%d)", path.name, seen[0])
            continue
        try:
            for _, row in read_rows(path):
                if row is None:
                    rows_rejected += 1
                    continue
                rows_ok += 1
                by_category[row["category"]] += row["amount"]
                by_month[row["date"].strftime("%Y-%m")] += row["amount"]
        except ValueError as exc:
            log.error("%s", exc)
            continue
        new_files.append((digest, path.name))
        log.info("OK   %s processed", path.name)

    total = round(sum(by_category.values()), 2)
    cur = db.execute("INSERT INTO runs (started_at, host, files_processed, rows_ok, "
                     "rows_rejected, total) VALUES (?,?,?,?,?,?)",
                     (started.isoformat(), host, len(new_files), rows_ok, rows_rejected, total))
    run_id = cur.lastrowid
    db.executemany("INSERT OR REPLACE INTO processed_files VALUES (?,?,?)",
                   [(d, n, run_id) for d, n in new_files])

    report_name = None
    if new_files:
        out_dir.mkdir(parents=True, exist_ok=True)
        stamp = started.strftime("%Y%m%d-%H%M%S")
        report_name = f"report_run{run_id:03d}_{stamp}"
        with (out_dir / f"{report_name}.csv").open("w", newline="") as fh:
            w = csv.writer(fh)
            w.writerow(["category", f"total_{args.currency.lower()}", "share_pct"])
            for cat, amt in sorted(by_category.items(), key=lambda kv: -kv[1]):
                w.writerow([cat, f"{amt:.2f}", f"{amt / total * 100:.1f}" if total else "0"])
            w.writerow(["TOTAL", f"{total:.2f}", "100.0"])
        summary = {
            "run_id": run_id, "generated_at": started.isoformat(), "container": host,
            "currency": args.currency, "files": [n for _, n in new_files],
            "rows_ok": rows_ok, "rows_rejected": rows_rejected, "total": total,
            "by_category": {k: round(v, 2) for k, v in sorted(by_category.items())},
            "by_month": {k: round(v, 2) for k, v in sorted(by_month.items())},
        }
        (out_dir / f"{report_name}.json").write_text(json.dumps(summary, indent=2))
        log.info("Wrote %s.csv and %s.json to %s", report_name, report_name, out_dir)
        for cat, amt in sorted(by_category.items(), key=lambda kv: -kv[1]):
            log.info("  %-15s %10.2f %s", cat, amt, args.currency)
        log.info("  %-15s %10.2f %s", "TOTAL", total, args.currency)
    else:
        log.info("No new files to process - nothing written")

    db.execute("UPDATE runs SET finished_at=?, report=? WHERE id=?",
               (datetime.now(timezone.utc).isoformat(), report_name, run_id))
    db.commit()
    db.close()
    log.info("Run #%d complete: %d file(s), %d rows ok, %d rejected. Exiting with code 0",
             run_id, len(new_files), rows_ok, rows_rejected)
    return 0


if __name__ == "__main__":
    sys.exit(main())
