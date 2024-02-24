#!/bin/bash -eu

echo '--- :cocoapods: Install Pods (required to check for outdated next)'
install_cocoapods

# Run `bundle exec pod outdated` and capture the output
outdated_pods=$(bundle exec pod outdated)

# Filter the outdated pods from the rest of the output
filtered_pods=$(echo "$outdated_pods" | grep -oP '- (\S+) \S+ -> \S+ \(latest version \S+\)')

# Check if we have any outdated pods to report
if [ -z "$filtered_pods" ]; then
  echo "No outdated pods to report."
else
# Create a Buildkite annotation with the filtered pods
  echo "$filtered_pods"
  buildkite-agent annotate --style "info" --context 'ctx-outdated-pods' <<< "$filtered_pods"
fi
