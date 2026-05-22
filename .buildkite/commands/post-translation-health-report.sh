#!/bin/bash -eu

# Generates a per-locale translation health report (key parity vs en.lproj,
# missing keys, drift) and appends it to the just-published GitHub release
# notes. Runs after a release is finalized.
#
# Per César's call (DoD C13): no release gate, report-only. The report is
# informational — it tells the team which locales have drifted so they
# can be triaged in a follow-up.
#
# Reads:
#   RELEASE_VERSION  e.g. "24.9.0". Falls back to most recent release.
#   GITHUB_TOKEN     for `gh` CLI.

echo "--- :bar_chart: Generating translation health report"

REPORT_FILE="/tmp/translation-health-report.md"
bundle exec rake -f fastlane/ai_translation/Rakefile translate:report > "${REPORT_FILE}"

echo "--- Report (first 20 lines) ---"
head -n 20 "${REPORT_FILE}"
echo "------------------------------"

# Drop as Buildkite annotation so the report is visible from the build page
# without needing to click out to GitHub.
buildkite-agent annotate --style 'info' --context translation-health < "${REPORT_FILE}" || true

# Determine the release tag to update.
if [[ -n "${RELEASE_VERSION:-}" ]]; then
  TAG="${RELEASE_VERSION}"
else
  TAG=$(gh release list --limit 1 --json tagName --jq '.[0].tagName')
fi

if [[ -z "${TAG}" ]]; then
  echo "No release tag resolved. Annotation posted, but release notes unchanged."
  exit 0
fi

echo "Appending report to release ${TAG}…"

EXISTING=$(gh release view "${TAG}" --json body --jq '.body')
TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)

NEW_BODY="${EXISTING}

---

## 🌐 Translation health (auto-generated ${TIMESTAMP})

$(cat "${REPORT_FILE}")
"

gh release edit "${TAG}" --notes "${NEW_BODY}"
echo "Translation health report appended to release ${TAG}."
