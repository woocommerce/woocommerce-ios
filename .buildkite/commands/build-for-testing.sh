#!/bin/bash -eu

if .buildkite/commands/should-skip-job.sh --job-type build; then
  exit 0
fi

"$(dirname "${BASH_SOURCE[0]}")/shared-set-up.sh"

echo "--- :writing_hand: Copy Files"
mkdir -pv ~/.configure/woocommerce-ios/secrets
cp -v fastlane/env/project.env.example ~/.configure/woocommerce-ios/secrets/project.env

echo "--- :hammer_and_wrench: Building"
# fastlane/logs feeds the warning count below; clear it so logs from a previous
# build (or the screenshots lane) on a reused checkout can't leak into the report.
rm -rf fastlane/logs || true
bundle exec fastlane build_for_testing

# Count warnings here rather than in the comparison step: the build log contains
# absolute paths rooted in this agent's checkout, so counting on another agent
# would fail to attribute any warning to the repo.
echo "--- :warning: Count build warnings"
# The warning guard is advisory: never fail the build over counting or upload issues.
if ruby .buildkite/commands/count-build-warnings.rb fastlane/logs build-warnings.json; then
  # upload_artifact stores to S3 for the comparison step; the buildkite-agent
  # upload makes the report visible in the build's Artifacts tab.
  upload_artifact build-warnings.json || echo "Failed to store the warning report; the comparison step will be skipped."
  buildkite-agent artifact upload build-warnings.json || echo "Failed to upload the warning report to the Artifacts tab."
else
  echo "Failed to count build warnings; the build warning comparison step will be skipped."
fi

echo "--- :arrow_up: Upload Build Products"
tar -cf build-products.tar DerivedData/Build/Products/
upload_artifact build-products.tar
