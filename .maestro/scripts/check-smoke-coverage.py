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
FIDELITY_RE = re.compile(r"^\s+fidelity:\s*(.+?)\s*$")
GAP_RE = re.compile(r"^\s+gap:\s*(.+?)\s*$")
P2_RE = re.compile(r"^#\s*p2:\s*(.+?)\s*$")


def parse_snapshot(path: Path) -> tuple[dict[str, dict[str, str]], set[str]]:
    items: dict[str, dict[str, str]] = {}
    duplicates: set[str] = set()
    current: str | None = None
    for line in path.read_text(encoding="utf-8").splitlines():
        id_match = ID_RE.match(line)
        if id_match:
            current = id_match.group(1)
            if current in items:
                duplicates.add(current)
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
        fidelity_match = FIDELITY_RE.match(line)
        if fidelity_match:
            items[current]["fidelity"] = fidelity_match.group(1).strip().strip('"')
            continue
        gap_match = GAP_RE.match(line)
        if gap_match:
            items[current]["gap"] = gap_match.group(1).strip().strip('"')
    return items, duplicates


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

    items, duplicates = parse_snapshot(args.coverage)
    flow_headers = parse_flow_headers(args.flows_dir)
    errors: list[str] = []

    for item_id in sorted(duplicates):
        errors.append(f"{args.coverage}: duplicate item id {item_id}")

    for item_id, data in sorted(items.items()):
        has_flow = bool(data.get("flow"))
        has_manual = bool(data.get("manual"))
        if has_flow and has_manual:
            errors.append(f"{args.coverage}: item {item_id} has both flow and manual reason")
        elif not has_flow and not has_manual:
            errors.append(f"{args.coverage}: item {item_id} has neither flow nor manual reason")
        elif has_flow:
            fidelity = data.get("fidelity", "full")
            if fidelity not in {"full", "partial"}:
                errors.append(f"{args.coverage}: item {item_id} has unknown fidelity {fidelity!r}")
            elif fidelity == "partial" and not data.get("gap"):
                errors.append(f"{args.coverage}: partial item {item_id} has no gap explanation")
            elif fidelity == "full" and data.get("gap"):
                errors.append(f"{args.coverage}: full item {item_id} must not declare a gap")
        elif data.get("fidelity") or data.get("gap"):
            errors.append(f"{args.coverage}: manual item {item_id} must not declare flow fidelity")

    known_ids = set(items)
    for flow, ids in flow_headers.items():
        if not ids:
            errors.append(f"{flow}: missing '# p2:' header")
        for item_id in sorted(ids - known_ids):
            errors.append(f"{flow}: unknown p2 id {item_id}")

        for item_id in sorted(ids & known_ids):
            mapped_flow = items[item_id].get("flow", "")
            if mapped_flow != flow:
                errors.append(f"{flow}: p2 id {item_id} maps to {mapped_flow or 'manual coverage'}")

    for item_id, data in sorted(items.items()):
        flow = data.get("flow", "")
        if flow and item_id not in flow_headers.get(flow, set()):
            errors.append(f"{args.coverage}: item {item_id} maps to {flow}, but that flow does not declare it")

    if errors:
        print("\n".join(errors), file=sys.stderr)
        return 1
    full = sum(1 for data in items.values() if data.get("flow") and data.get("fidelity", "full") == "full")
    partial = sum(1 for data in items.values() if data.get("flow") and data.get("fidelity") == "partial")
    manual = sum(1 for data in items.values() if data.get("manual"))
    print(
        f"Coverage snapshot OK: {len(items)} items, {len(flow_headers)} flows "
        f"({full} full, {partial} partial, {manual} manual)"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
