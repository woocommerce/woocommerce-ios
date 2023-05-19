#!/bin/bash -eu

# Send a GET request using curl and store the response in RAW_TEST_RESULTS variable
echo "--- :buildkite: Getting BK Annotation API Response"
RAW_TEST_RESULTS=$(curl --location --request GET "https://api.buildkite.com/v2/organizations/$BUILDKITE_ORGANIZATION_SLUG/pipelines/$BUILDKITE_PIPELINE_SLUG/builds/$BUILDKITE_BUILD_NUMBER/annotations" \
--header 'Accept: application/json' \
--header "Authorization: Bearer $BUILDKITE_TOKEN")

# To get results in proper JSON format
echo "--- :json: Getting Results in JSON"
TEST_RESULTS=$(echo "$RAW_TEST_RESULTS" | tr -d '\n' | jq '.')

# To filter out only UI Tests and those that are errors
echo "--- :scissors: Filtering Results"
UI_TEST_RESULTS=$(echo "$TEST_RESULTS" | jq 'map(select(.context | contains("Unit Tests") | not) | select(.style == "error"))')

# Filter out test summary and failing tests names from body_html
echo "--- :test_tube: Getting Test Summary and Failing Tests list"
TEST_SUMMARY=$(echo $UI_TEST_RESULTS | sed -n 's/.*<h4>\([^<]*\)<\/h4>.*/\1/p')
FAILING_TESTS=$(echo $UI_TEST_RESULTS | grep -o '<tt>[^<]*<\/tt>' | sed 's/<\.*tt>//g' | sed 's/<\/tt>//g' | grep 'test')

# Form Slack message payload
echo "--- :slack: Create Slack Message Payload"
SLACK_MESSAGE_PAYLOAD=$(cat <<EOF
{
    "blocks": [
        {
            "type": "section",
            "text": {
                "type": "mrkdwn",
                "text": "*Platform:* $BUILDKITE_PIPELINE_NAME *Build Author:* $BUILDKITE_BUILD_AUTHOR \n"
            },
            "accessory": {
                "type": "button",
                "text": {
                    "type": "plain_text",
                    "text": "Build",
                    "emoji": true
                },
                "value": "build",
                "url": "https://buildkite.com/$BUILDKITE_ORGANIZATION_SLUG/$BUILDKITE_PIPELINE_SLUG/builds/$BUILDKITE_BUILD_NUMBER",
                "action_id": "button-action"
            }
        },
        {
            "type": "divider"
        },
        {
            "type": "section",
            "text": {
                "type": "mrkdwn",
                "text": "*Summary:* $TEST_SUMMARY\n*Failing Test(s):* $FAILING_TESTS"
            }
        }
    ]
}
EOF
)

# Run curl command to send message to Slack
echo "--- :slack: Sending Slack Notification"
curl -X POST -H 'Content-type: application/json' --data "$SLACK_MESSAGE_PAYLOAD" https://hooks.slack.com/services/$SLACK_WEBHOOK_URL
echo "--- :slack: Notification Sent!"
