#!/bin/bash -eu

# Compares a current warning-count JSON against the committed baseline.
# Fails (exit 1) if any file EXCEEDS its baseline count. Files absent from the
# baseline count as 0, so new files must be born free of strict-concurrency
# warnings. Decreases never fail — they are reported so the baseline can be
# shrunk in the same PR (edit baseline.json; that is the expected escape hatch
# when an increase is genuinely justified, visible to reviewers).
#
# Usage:
#   Scripts/StrictConcurrency/compare-baseline.sh <current.json> [baseline.json]

CURRENT="${1:?usage: compare-baseline.sh <current.json> [baseline.json]}"
BASELINE="${2:-$(git rev-parse --show-toplevel)/Scripts/StrictConcurrency/baseline.json}"

CURRENT="$CURRENT" BASELINE="$BASELINE" python3 - <<'PY'
import json, os, sys

current = json.load(open(os.environ["CURRENT"]))["perFile"]
baseline = json.load(open(os.environ["BASELINE"]))["perFile"]

regressions = []
improvements = []
for path, count in sorted(current.items()):
    allowed = baseline.get(path, 0)
    if count > allowed:
        regressions.append((path, allowed, count))
    elif count < allowed:
        improvements.append((path, allowed, count))
for path, allowed in sorted(baseline.items()):
    if path not in current and allowed > 0:
        improvements.append((path, allowed, 0))

if improvements:
    print(f"{len(improvements)} file(s) improved vs baseline — shrink baseline.json:")
    for path, allowed, count in improvements[:20]:
        print(f"  {path}: {allowed} -> {count}")

if regressions:
    print(f"\nFAIL: {len(regressions)} file(s) exceed the strict-concurrency baseline:")
    for path, allowed, count in regressions:
        print(f"  {path}: baseline {allowed}, now {count} (+{count - allowed})")
    sys.exit(1)

print(f"\nOK: no file exceeds the baseline (current total {sum(current.values())}, baseline total {sum(baseline.values())}).")
PY
