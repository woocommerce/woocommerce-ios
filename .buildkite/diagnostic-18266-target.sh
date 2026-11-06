#!/bin/bash
set -eu
PROBE_DEVICE="$1"
BUILDKITE_BUILD_ID=01a1b0ed-9b45-4577-a1ca-58a83d25ec09 download_artifact build-products.tar
tar -xf build-products.tar
XCTESTRUN=$(find DerivedData/Build/Products -maxdepth 1 -name '*UnitTests*.xctestrun' -print -quit)
test -n "$XCTESTRUN"
date -u
sysctl kern.boottime
xcrun simctl list --json > simulator-before.json
xcrun simctl runtime list > runtimes-before.txt
set +e
xcodebuild -xctestrun "$XCTESTRUN" \
  -destination "platform=iOS Simulator,name=$PROBE_DEVICE" \
  -only-testing:WooCommerceTests -parallel-testing-enabled NO \
  -collect-test-diagnostics on-failure \
  -resultBundlePath probe-result.xcresult test-without-building > probe.log 2>&1
STATUS=$?
set -e
date -u
xcrun simctl list --json > simulator-after.json || true
xcrun simctl runtime list > runtimes-after.txt || true
for REPORT in "$HOME"/Library/Logs/DiagnosticReports/WooCommerce*.ips; do
  if [ -f "$REPORT" ]; then cp "$REPORT" .; fi
done
if [ -d probe-result.xcresult ]; then zip -rq probe-result.xcresult.zip probe-result.xcresult; fi
tail -n 50 probe.log
exit "$STATUS"
