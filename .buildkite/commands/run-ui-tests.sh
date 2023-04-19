#!/bin/bash -eu

TEST_NAME=$1
DEVICE=$2

echo "Running $TEST_NAME on $DEVICE"

# Run this at the start to fail early if value not available
echo '--- :test-analytics: Configuring Test Analytics'
if [[ $DEVICE =~ ^iPhone ]]; then
  export BUILDKITE_ANALYTICS_TOKEN=$BUILDKITE_ANALYTICS_TOKEN_UI_TESTS_IPHONE
else
  export BUILDKITE_ANALYTICS_TOKEN=$BUILDKITE_ANALYTICS_TOKEN_UI_TESTS_IPAD
fi

echo "--- 📦 Downloading Build Artifacts"
buildkite-agent artifact download build-products.tar .
tar -xf build-products.tar

echo "--- :rubygems: Setting up Gems"
install_gems

echo "--- :cocoapods: Setting up Pods"
install_cocoapods

echo "--- 🧪 Testing"	
xcrun simctl list >> /dev/null	
rake mocks &	
set +e	

RUN=10
TESTS_EXIT_STATUS=0
for ((i=1; i<=RUN; i++)); do
    echo "--- RUN $i"
    bundle exec fastlane test_without_building name:"$TEST_NAME" device:"$DEVICE"
    INDIVIDUAL_EXIT_STATUS=$?

    echo "--- 📦 Zipping test results Run: $i Status: $INDIVIDUAL_EXIT_STATUS"
    cd fastlane/test_output/ && zip -rq WooCommerce-run-"$i"-status-"$INDIVIDUAL_EXIT_STATUS".xcresult.zip WooCommerce.xcresult
    rm -rf WooCommerce.xcresult
    cd ../../

    if [ "$INDIVIDUAL_EXIT_STATUS" -ne 0 ]; then
        TESTS_EXIT_STATUS="$INDIVIDUAL_EXIT_STATUS"
    fi
done
set -e

exit $TESTS_EXIT_STATUS
