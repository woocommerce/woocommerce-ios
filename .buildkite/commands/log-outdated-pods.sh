#!/bin/bash -eu

echo '--- :cocoapods: Install Pods (required before checking for outdated pods)'
install_cocoapods

# Run `bundle exec pod outdated` and capture the output
OUTDATED_PODS=$(bundle exec pod outdated)

# Filter the outdated pods from the rest of the output
FILTERED_PODS=$(echo "$OUTDATED_PODS" | grep -oE '\- ([^[:space:]]+) [^[:space:]]+ -> [^[:space:]]+ \(latest version [^[:space:]]+\)')

# Check if we have any outdated pods to report
if [ -z "$FILTERED_PODS" ]; then
  echo "No outdated pods to report."
else
# Create a Buildkite annotation with the filtered pods
  echo '--- :cocoapods: Outdated Pods'
  echo $FILTERED_PODS

  MESSAGE="### Outdated Pods

  $FILTERED_PODS"

  buildkite-agent annotate "$MESSAGE" --style 'info' --context 'ctx-outdated-pods'
fi
