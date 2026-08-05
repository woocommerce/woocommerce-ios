#!/usr/bin/env python3
"""Render a concise Buildkite-ready Markdown summary from Maestro artifacts."""

from __future__ import annotations

import argparse
import json
import os
import xml.etree.ElementTree as ET
from pathlib import Path


def junit_totals(path: Path) -> tuple[int, int, int, list[str]]:
    root = ET.parse(path).getroot()
    suites = [root] if root.tag == "testsuite" else list(root.findall("testsuite"))
    tests = sum(int(suite.get("tests", len(suite.findall("testcase")))) for suite in suites)
    failures = sum(
        int(suite.get("failures", "0")) + int(suite.get("errors", "0")) for suite in suites
    )
    skipped = sum(int(suite.get("skipped", "0")) for suite in suites)
    failed_names = [
        case.get("name", "unnamed")
        for case in root.iter("testcase")
        if case.find("failure") is not None or case.find("error") is not None
    ]
    return tests, failures, skipped, failed_names


def render(junit: Path, summary: Path | None = None) -> str:
    tests, failures, skipped, failed_names = junit_totals(junit)
    status = "PASS" if failures == 0 else "FAIL"
    if summary and summary.is_file():
        status = str(json.loads(summary.read_text(encoding="utf-8")).get("status", status))
    lines = [
        f"### Maestro smoke: {status}",
        "",
        f"{tests} tests · {failures} failures · {skipped} skipped",
    ]
    if failed_names:
        lines.extend(["", "Failures:"])
        lines.extend(f"- `{name}`" for name in failed_names[:8])
    build_url = os.environ.get("BUILDKITE_BUILD_URL")
    job_id = os.environ.get("BUILDKITE_JOB_ID")
    if build_url and job_id:
        lines.extend(["", f"[Open job artifacts]({build_url}#job-{job_id})"])
    return "\n".join(lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--junit", required=True, type=Path)
    parser.add_argument("--summary", type=Path)
    args = parser.parse_args()
    print(render(args.junit, args.summary), end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
