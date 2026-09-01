#!/bin/bash -eu

# Counts Swift strict-concurrency warnings for the whole workspace and writes
# per-file counts as JSON (the format compared against baseline.json).
#
# The build forces SWIFT_STRICT_CONCURRENCY=complete on the xcodebuild command
# line — the only layer that reaches SPM package targets as well as Xcode ones.
#
# Usage:
#   Scripts/StrictConcurrency/count-warnings.sh [output.json]
#
# Environment:
#   STRICT_CONCURRENCY_LOG           Parse this existing build log instead of
#                                    building (fast; used by tests).
#   STRICT_CONCURRENCY_DERIVED_DATA  Derived data path (default: fresh temp dir,
#                                    which forces the clean build the count needs).

REPO_ROOT="$(git rev-parse --show-toplevel)"
OUTPUT="${1:-$REPO_ROOT/Scripts/StrictConcurrency/current.json}"
LOG_FILE="${STRICT_CONCURRENCY_LOG:-}"

if [[ -z "$LOG_FILE" ]]; then
  DERIVED_DATA="${STRICT_CONCURRENCY_DERIVED_DATA:-$(mktemp -d)/DerivedData}"
  LOG_FILE="$(mktemp -d)/strict-concurrency-build.log"
  echo "Building with SWIFT_STRICT_CONCURRENCY=complete (log: $LOG_FILE)..."
  set +e
  xcodebuild -workspace "$REPO_ROOT/WooCommerce.xcworkspace" \
    -scheme WooCommerce \
    -destination 'generic/platform=iOS Simulator' \
    -derivedDataPath "$DERIVED_DATA" \
    build \
    SWIFT_STRICT_CONCURRENCY=complete \
    CODE_SIGNING_ALLOWED=NO > "$LOG_FILE" 2>&1
  BUILD_STATUS=$?
  set -e
  if [[ $BUILD_STATUS -ne 0 ]]; then
    echo "ERROR: build failed — warning counts from a partial build are unusable." >&2
    echo "--- compiler error diagnostics (if any):" >&2
    grep -E "^/.*\.swift:[0-9]+:[0-9]+: error: " "$LOG_FILE" | sort -u | head -20 >&2
    echo "--- last 150 lines of the build log (failing commands / crash traces):" >&2
    tail -n 150 "$LOG_FILE" >&2
    # Keep the full log where CI can pick it up as an artifact.
    cp "$LOG_FILE" "$REPO_ROOT/strict-concurrency-build-failed.log" 2>/dev/null || true
    exit $BUILD_STATUS
  fi
fi

REPO_ROOT="$REPO_ROOT" LOG_FILE="$LOG_FILE" OUTPUT="$OUTPUT" python3 - <<'PY'
import json, os, re, sys
from collections import defaultdict

repo_root = os.environ["REPO_ROOT"].rstrip("/") + "/"
pattern = re.compile(r"^(/.*?\.swift):(\d+):(\d+): warning: (.*)$")

unique = set()
with open(os.environ["LOG_FILE"], errors="replace") as f:
    for line in f:
        m = pattern.match(line.rstrip("\n"))
        if m and m.group(1).startswith(repo_root):
            unique.add((m.group(1), m.group(2), m.group(3), m.group(4)))

per_file = defaultdict(int)
for path, _, _, _ in unique:
    per_file[path[len(repo_root):]] += 1

result = {
    "total": sum(per_file.values()),
    "perFile": dict(sorted(per_file.items())),
}
with open(os.environ["OUTPUT"], "w") as f:
    json.dump(result, f, indent=2, sort_keys=True)
    f.write("\n")
print(f"{result['total']} unique strict-concurrency warnings in {len(per_file)} files -> {os.environ['OUTPUT']}")
PY
