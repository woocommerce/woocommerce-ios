#!/bin/bash -eu

if .buildkite/commands/should-skip-job.sh --job-type validation; then
  exit 0
fi

echo "--- 📦 Downloading Build Artifacts"
download_artifact build-products.tar
tar -xf build-products.tar

"$(dirname "${BASH_SOURCE[0]}")/shared-set-up.sh"

echo "--- 🧪 Testing"
# Temporary capture for the 600-second simulator diagnostics timeout.
DIAGNOSTICS_DIR="$PWD/fastlane/test_output/process-diagnostics"
mkdir -p "$DIAGNOSTICS_DIR"
python3 -u - "$DIAGNOSTICS_DIR" > "$DIAGNOSTICS_DIR/watcher.log" 2>&1 <<'PY' &
import signal
import subprocess
import sys
import threading
import time
from pathlib import Path

output = Path(sys.argv[1])
stopped = threading.Event()
signal.signal(signal.SIGTERM, lambda *_: stopped.set())
sampled = set()
started = time.monotonic()
names = {'xcodebuild', 'testmanagerd', 'simctl', 'diagnose', 'launchd_sim',
         'log', 'lsdiagnose', 'darwinup', 'swcutil',
         'com.apple.CoreSimulator.CoreSimulatorService'}
while not stopped.is_set():
    rows = []
    snapshot = subprocess.check_output(['ps', '-axo', 'pid=,ppid=,etime=,comm='], universal_newlines=True, timeout=5)
    for line in snapshot.splitlines():
        fields = line.split(None, 3)
        if len(fields) != 4:
            continue
        pid, parent, elapsed, command = fields
        days, clock = elapsed.split('-', 1) if '-' in elapsed else ('0', elapsed)
        seconds = int(days) * 86400 + sum(int(v) * 60 ** i for i, v in enumerate(reversed(clock.split(':'))))
        rows.append((int(pid), int(parent), seconds, command.rsplit('/', 1)[-1], line))
    with (output / 'processes.log').open('a') as log:
        log.write(time.strftime('%Y-%m-%d %H:%M:%S UTC', time.gmtime()) + '\n')
        log.write('\n'.join(row[4] for row in rows if row[3] in names) + '\n')
    roots = [row for row in rows if row[3] == 'simctl' and row[2] >= 60]
    targets = roots[:1]
    if targets:
        children = [row for row in rows if row[1] == targets[0][0]]
        targets += sorted(children, key=lambda row: row[2], reverse=True)[:1]
        targets += sorted([row for row in rows if row[3] in {'log', 'lsdiagnose', 'darwinup', 'swcutil'} and row[2] >= 60],
                          key=lambda row: row[2], reverse=True)[:1]
    if roots or time.monotonic() - started >= 720:
        targets += [row for row in rows if row[3] == 'com.apple.CoreSimulator.CoreSimulatorService'][:1]
        targets += [row for row in rows if row[3] == 'xcodebuild'][:1]
        if not roots:
            targets += sorted([row for row in rows if row[3] == 'testmanagerd'], key=lambda row: row[2], reverse=True)[:1]
    for pid, _, _, name, _ in targets:
        key = (pid, roots[0][0] if roots else 'fallback')
        if stopped.is_set() or key in sampled:
            continue
        sampled.add(key)
        try:
            subprocess.run(['sample', str(pid), '5', '-file', str(output / ('%s-%d-%s.sample.txt' % (name, pid, key[1])))],
                           timeout=15, check=False)
        except (OSError, subprocess.TimeoutExpired) as error:
            print('Sample failed for PID %d: %s' % (pid, error), flush=True)
    stopped.wait(30)
PY
DIAGNOSTICS_PID=$!
trap 'kill "$DIAGNOSTICS_PID" 2>/dev/null || true; wait "$DIAGNOSTICS_PID" 2>/dev/null || true' EXIT

set +e
bundle exec fastlane test_without_building name:UnitTests
TESTS_EXIT_STATUS=$?
set -e

kill "$DIAGNOSTICS_PID" 2>/dev/null || true
wait "$DIAGNOSTICS_PID" 2>/dev/null || true
trap - EXIT
buildkite-agent artifact upload "$DIAGNOSTICS_DIR/*" || true

if [[ "$TESTS_EXIT_STATUS" -ne 0 ]]; then
  # Keep the (otherwise collapsed) current "Testing" section open in Buildkite logs on error. See https://buildkite.com/docs/pipelines/managing-log-output#collapsing-output
  echo "^^^ +++"
  echo "Unit Tests failed!"
fi

echo "--- 📦 Zipping test results"
cd fastlane/test_output/ && zip -rq WooCommerce.xcresult.zip WooCommerce.xcresult && cd -

echo "--- 🚦 Report Tests Status"
if [[ $TESTS_EXIT_STATUS -eq 0 ]]; then
  echo "Unit Tests seems to have passed (exit code 0). All good 👍"
else
  echo "The Unit Tests, which ran inside the '🧪 Testing' section above in the logs, have failed."
  echo "For more details about the failed tests, check the Buildkite annotation, the logs under the '🧪 Testing' section and the \`.xcresult\` and test reports in Buildkite artifacts."
fi

if [[ $BUILDKITE_BRANCH == trunk ]] || [[ $BUILDKITE_BRANCH == release/* ]]; then
    annotate_test_failures "fastlane/test_output/report.junit" --slack "build-and-ship"
else
    annotate_test_failures "fastlane/test_output/report.junit"
fi

exit $TESTS_EXIT_STATUS
