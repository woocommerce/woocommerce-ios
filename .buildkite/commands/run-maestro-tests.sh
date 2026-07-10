#!/bin/bash
set -euo pipefail

PROFILE="${MAESTRO_PROFILE:-release}"
APP_VARIANT="${MAESTRO_APP_VARIANT:-debug}"
APP_ARTIFACT="${MAESTRO_APP_ARTIFACT:-build-products.tar}"
APP_SOURCE_BUILD_ID="${MAESTRO_APP_SOURCE_BUILD_ID:-}"
APP_PATH="${MAESTRO_APP_PATH:-}"
DEVICE="${MAESTRO_DEVICE:-}"
OUTPUT_KEY="${BUILDKITE_JOB_ID:-local-$$}"
OUTPUT_ROOT="${MAESTRO_OUTPUT_DIR:-build/maestro/$OUTPUT_KEY}"

if [[ "${BUILDKITE:-false}" == "true" && -e .maestro/.env.local ]]; then
  echo "CI Maestro runs must use protected environment variables, not .maestro/.env.local." >&2
  exit 2
fi

case "$PROFILE" in
  release|burst|pos-ipad|ios-system) ;;
  *)
    echo "Unsupported CI Maestro profile: $PROFILE" >&2
    exit 2
    ;;
esac

case "$APP_VARIANT" in
  debug) ;;
  alpha|prototype)
    if [[ -z "$APP_PATH" ]]; then
      echo "MAESTRO_APP_PATH is required for an Alpha/prototype simulator app." >&2
      exit 2
    fi
    ;;
  *)
    echo "MAESTRO_APP_VARIANT must be debug, alpha, or prototype." >&2
    exit 2
    ;;
esac

if [[ -z "${MAESTRO_CI_RESOURCE_KEY:-}" || "${MAESTRO_CI_RESOURCE_KEY}" == "unconfigured" ]]; then
  echo "MAESTRO_CI_RESOURCE_KEY must be a protected, opaque identifier for the configured test store/account." >&2
  exit 2
fi

required_environment=(
  MAESTRO_WOO_LAB_JETPACK_STORE_URL
  MAESTRO_WOO_LAB_WPCOM_EMAIL
  MAESTRO_WOO_LAB_WPCOM_PASSWORD
)
for variable in "${required_environment[@]}"; do
  if [[ -z "${!variable:-}" ]]; then
    echo "Missing protected environment variable: $variable" >&2
    exit 2
  fi
done

echo "--- :package: Downloading simulator app artifact"
if [[ ! -e "$APP_ARTIFACT" ]]; then
  if [[ -n "$APP_SOURCE_BUILD_ID" ]]; then
    buildkite-agent artifact download "$APP_ARTIFACT" . --build "$APP_SOURCE_BUILD_ID"
  else
    download_artifact "$APP_ARTIFACT"
  fi
fi

case "$APP_ARTIFACT" in
  *.tar) tar -xf "$APP_ARTIFACT" ;;
  *.tar.gz|*.tgz) tar -xzf "$APP_ARTIFACT" ;;
  *.zip) ditto -x -k "$APP_ARTIFACT" . ;;
esac

if [[ -z "$APP_PATH" ]]; then
  default_app="DerivedData/Build/Products/Debug-iphonesimulator/WooCommerce.app"
  if [[ -d "$default_app" ]]; then
    APP_PATH="$default_app"
  else
    app_count=0
    while IFS= read -r candidate; do
      APP_PATH="$candidate"
      app_count=$((app_count + 1))
    done < <(find DerivedData/Build/Products -type d -path '*-iphonesimulator/*.app' -prune 2>/dev/null)
    if [[ "$app_count" -ne 1 ]]; then
      echo "Expected one simulator .app in the Debug artifact; found $app_count. Set MAESTRO_APP_PATH explicitly." >&2
      exit 2
    fi
  fi
fi

if [[ ! -d "$APP_PATH" || "$APP_PATH" != *.app ]]; then
  echo "Simulator app was not found at MAESTRO_APP_PATH: $APP_PATH" >&2
  exit 2
fi

mkdir -p "$OUTPUT_ROOT"

runner=(
  .maestro/scripts/run-smoke-tests.sh
  --app "$APP_PATH"
  --profile "$PROFILE"
  --output-dir "$OUTPUT_ROOT"
  --no-open
)
if [[ -n "$DEVICE" ]]; then
  runner+=(--device "$DEVICE")
fi

echo "--- :iphone: Running Maestro $PROFILE profile with the $APP_VARIANT simulator app"
set +e
"${runner[@]}"
status=$?
set -e

report_count=$(find "$OUTPUT_ROOT" -type f -name report.xml | wc -l | tr -d ' ')
html_count=$(find "$OUTPUT_ROOT" -type f -name report.html | wc -l | tr -d ' ')
if [[ "$report_count" -eq 0 || "$html_count" -eq 0 ]]; then
  echo "Maestro did not produce both report.xml and report.html under $OUTPUT_ROOT." >&2
  if [[ "$status" -eq 0 ]]; then
    status=1
  fi
else
  echo "Maestro produced $report_count JUnit report(s) and $html_count HTML report(s)."
fi

exit "$status"
