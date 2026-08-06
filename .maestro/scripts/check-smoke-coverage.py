#!/usr/bin/env python3
"""Offline coverage check for Maestro smoke flows."""

from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path


ID_RE = re.compile(r"^\s*-\s+id:\s*([A-Za-z0-9_.-]+)\s*$")
FLOW_RE = re.compile(r"^\s+flow:\s*(.+?)\s*$")
MANUAL_RE = re.compile(r"^\s+manual:\s*(.+?)\s*$")
P2_RE = re.compile(r"^#\s*p2:\s*(.+?)\s*$")


def parse_snapshot(path: Path) -> dict[str, dict[str, str]]:
    items: dict[str, dict[str, str]] = {}
    current: str | None = None
    for line in path.read_text(encoding="utf-8").splitlines():
        id_match = ID_RE.match(line)
        if id_match:
            current = id_match.group(1)
            items[current] = {}
            continue
        if current is None:
            continue
        flow_match = FLOW_RE.match(line)
        if flow_match:
            items[current]["flow"] = flow_match.group(1).strip().strip('"')
            continue
        manual_match = MANUAL_RE.match(line)
        if manual_match:
            items[current]["manual"] = manual_match.group(1).strip().strip('"')
            continue
    return items


def parse_flow_headers(flows_dir: Path) -> dict[str, set[str]]:
    result: dict[str, set[str]] = {}
    for flow in sorted(flows_dir.glob("*.yaml")):
        ids: set[str] = set()
        for line in flow.read_text(encoding="utf-8").splitlines()[:40]:
            match = P2_RE.match(line)
            if match:
                ids.update(item.strip() for item in match.group(1).split(",") if item.strip())
        result[str(flow)] = ids
    return result


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--coverage", default=".maestro/smoke-coverage.yaml", type=Path)
    parser.add_argument("--flows-dir", default=".maestro/flows", type=Path)
    args = parser.parse_args()

    items = parse_snapshot(args.coverage)
    flow_headers = parse_flow_headers(args.flows_dir)
    errors: list[str] = []

    for item_id, data in sorted(items.items()):
        if not data.get("flow") and not data.get("manual"):
            errors.append(f"{args.coverage}: item {item_id} has neither flow nor manual reason")

    known_ids = set(items)
    header_ids = set().union(*flow_headers.values()) if flow_headers else set()
    for flow, ids in flow_headers.items():
        if not ids:
            errors.append(f"{flow}: missing '# p2:' header")
        for item_id in sorted(ids - known_ids):
            errors.append(f"{flow}: unknown p2 id {item_id}")

    for item_id, data in sorted(items.items()):
        flow = data.get("flow", "")
        if flow and item_id not in header_ids:
            errors.append(f"{args.coverage}: item {item_id} maps to {flow}, but no flow header declares it")

    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    print(f"Coverage snapshot OK: {len(items)} items, {len(flow_headers)} flows")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
