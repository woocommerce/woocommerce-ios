#!/bin/bash -eu

RESULTS=$1

ASSERTION_FAILURES_COUNT=$(echo "$RESULTS" | jq -r '.assertion_failures_count')
FAILED_TESTS_ARRAY=$(echo "$RESULTS" | jq -r '.tests')

FAILING_TESTS=$(echo "$FAILED_TESTS_ARRAY" | jq -c '.[]' | while IFS= read -r test; do
    name=$(echo "$test" | jq -r '.name')
    classname=$(echo "$test" | jq -r '.classname')
    echo "$name in $classname"
done | awk '{ printf "%s\n", $0 }' | sed 's/,$//')
echo $FAILING_TESTS

# Form Slack message payload
echo "--- :slack: Create Slack Message Payload"
SLACK_MESSAGE_PAYLOAD=$(cat <<EOF
{
    "blocks": [
        {
            "type": "section",
            "text": {
                "type": "mrkdwn",
                "text": "*Platform:* $BUILDKITE_PIPELINE_NAME *Build Author:* $BUILDKITE_BUILD_AUTHOR *Failures Count:* $ASSERTION_FAILURES_COUNT\n"
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
                "text": "*Failing Test(s):* $FAILING_TESTS"
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
