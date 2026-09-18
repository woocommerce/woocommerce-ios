#!/bin/bash -eu

# Lowers the committed baseline to match a measured result.
#
# A migration slice removes warnings, so its CI run reports "N file(s) improved".
# This script folds those improvements into baseline.json.
#
# It only ever LOWERS counts: for each file it keeps min(baseline, current), and drops
# files that reached zero. Files whose count went UP are left at their baseline value and
# reported, because accepting an increase is a deliberate decision a reviewer should see —
# copying a failing run's numbers over the baseline would silently launder a regression.
# To raise a count on purpose, edit baseline.json by hand and say why in the PR.
#
# The input must come from a real CI measurement (the strict-concurrency-current.json
# artifact). Counts from an incremental local build are an undercount: Xcode only reports
# diagnostics for the files it recompiled, so committing those would hide real debt.
#
# Usage:
#   Scripts/StrictConcurrency/update-baseline.sh <current.json> [baseline.json]

CURRENT="${1:?usage: update-baseline.sh <current.json> [baseline.json]}"
BASELINE="${2:-$(git rev-parse --show-toplevel)/Scripts/StrictConcurrency/baseline.json}"

CURRENT="$CURRENT" BASELINE="$BASELINE" python3 - <<'PY'
import json, os

current = json.load(open(os.environ["CURRENT"]))["perFile"]
baseline_path = os.environ["BASELINE"]
baseline = json.load(open(baseline_path))["perFile"]

lowered, removed, ignored = [], [], []
updated = {}
for path, allowed in baseline.items():
    now = current.get(path, 0)
    if now < allowed:
        (removed if now == 0 else lowered).append((path, allowed, now))
        if now:
            updated[path] = now
    else:
        if now > allowed:
            ignored.append((path, allowed, now))
        updated[path] = allowed

for path, allowed, now in lowered:
    print(f"lowered  {path}: {allowed} -> {now}")
for path, allowed, now in removed:
    print(f"cleared  {path}: {allowed} -> 0")

if ignored:
    print(f"\n{len(ignored)} file(s) INCREASED and were left untouched — fix them, or raise "
          f"their baseline by hand and explain why in the PR:")
    for path, allowed, now in ignored:
        print(f"  {path}: baseline {allowed}, now {now} (+{now - allowed})")

if not lowered and not removed:
    print("No improvements to fold in; baseline unchanged.")
else:
    result = {"total": sum(updated.values()), "perFile": dict(sorted(updated.items()))}
    with open(baseline_path, "w") as f:
        json.dump(result, f, indent=2, sort_keys=True)
        f.write("\n")
    print(f"\nBaseline now {result['total']} warnings across {len(result['perFile'])} files "
          f"({len(lowered) + len(removed)} file(s) improved).")
PY
