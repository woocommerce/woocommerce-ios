#!/bin/bash -eu

echo "--- :arrow_down: Download build-products.tar 3 times in parallel"
for i in 1 2 3; do
  mkdir -p "download-$i"
  ( SECONDS=0
    if download_artifact build-products.tar "download-$i/" > "download-$i.log" 2>&1; then status=0; else status=$?; fi
    echo "Download $i: exit $status after ${SECONDS}s"
  ) &
done
wait

echo "--- :mag: Download results"
for i in 1 2 3; do
  grep -E "^(Downloading from|download: |'.*Falling back|fatal error)" "download-$i.log" | sed "s/^/[$i] /" || true
done
buildkite-agent artifact upload "download-*.log"
