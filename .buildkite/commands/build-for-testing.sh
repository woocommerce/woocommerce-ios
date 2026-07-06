#!/bin/bash -eu

if .buildkite/commands/should-skip-job.sh --job-type build; then
  exit 0
fi

"$(dirname "${BASH_SOURCE[0]}")/shared-set-up.sh"

echo "--- :writing_hand: Copy Files"
mkdir -pv ~/.configure/woocommerce-ios/secrets
cp -v fastlane/env/project.env.example ~/.configure/woocommerce-ios/secrets/project.env

echo "--- :hammer_and_wrench: Building"
bundle exec fastlane build_for_testing

# Count warnings here rather than in the comparison step: the build log contains
# absolute paths rooted in this agent's checkout, so counting on another agent
# would fail to attribute any warning to the repo.
echo "--- :warning: Count build warnings"
if .buildkite/commands/count-build-warnings.sh fastlane/logs build-warnings.json; then
  upload_artifact build-warnings.json
else
  echo "Failed to count build warnings; the build warning comparison step will be skipped."
fi

echo "--- :arrow_up: Upload Build Products"
tar -cf build-products.tar DerivedData/Build/Products/
upload_artifact build-products.tar
