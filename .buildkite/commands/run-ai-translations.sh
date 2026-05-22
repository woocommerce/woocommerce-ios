#!/bin/bash -eu

# Runs the AI translation engine on a PR branch.
#
# When the PR has changes to WooCommerce/Resources/en.lproj/, this script
# runs `rake translate:incremental` for every supported locale, commits
# the resulting changes back to the PR branch as a separate "Translate:"
# commit, and exits.
#
# Per the team's policy (see project_ai_translations_pipeline.md), the
# bot's commits do NOT auto-merge — they push to the PR branch like a
# co-author and the PR author still hits merge after review.
#
# Hybrid CI gate (per DoD C13 / Jorge's alignment report):
#   - Same-repo PRs: STRICT. Validator failures, missing-secret, push errors
#     all block the PR. The pipeline.yml step does NOT use soft_fail so a
#     non-zero exit from this script fails the build.
#   - Fork PRs: SOFT. We exit 0 with an annotation so external contributors
#     aren't blocked by missing secrets they cannot provide. The release-time
#     health report (post-translation-health-report.sh) is the backstop.
#
# Skipped (exit 0, no failure) when:
#   - the build is not a PR (e.g. trunk / release branches)
#   - the PR is from a fork (annotated; translation will be done on a
#     same-repo PR or by the release sweep)
#   - no EN strings changed in the PR
#   - HEAD is already a translation-bot commit (loop prevention)
#
# Fails (exit 1) when:
#   - it's a same-repo PR and ANTHROPIC_API_KEY is not set (secret broken)
#   - rake translate:incremental returns non-zero (validator failure)
#   - the push of the translation commit fails
#
# Reads:
#   BUILDKITE_PULL_REQUEST          PR number ("false" if not a PR)
#   BUILDKITE_PULL_REQUEST_BASE_BRANCH
#   BUILDKITE_BRANCH                current branch
#   BUILDKITE_PULL_REQUEST_REPO     git URL of PR head repo
#   BUILDKITE_REPO                  git URL of main repo
#   ANTHROPIC_API_KEY               required for actual translation

BOT_NAME="WooCommerce Translation Bot"
BOT_EMAIL="translation-bot@noreply.woocommerce.com"
COMMIT_PREFIX="Translate:"

echo "--- :globe_with_meridians: AI Translation"

if [[ "${BUILDKITE_PULL_REQUEST:-false}" == "false" ]]; then
  echo "Skipping: not a pull request build."
  exit 0
fi

if [[ "${BUILDKITE_PULL_REQUEST_REPO:-}" != "" && "${BUILDKITE_PULL_REQUEST_REPO}" != "${BUILDKITE_REPO}" ]]; then
  echo "Skipping: PR is from a fork (${BUILDKITE_PULL_REQUEST_REPO})."
  echo "Translation bot cannot push back to forks; the release-time sweep will pick up missing translations."
  buildkite-agent annotate --style 'info' --context ai-translation-fork \
    "AI translation skipped: PR is from a fork. Maintainer or release sweep will translate." || true
  exit 0
fi

if [[ -z "${ANTHROPIC_API_KEY:-}" ]]; then
  # Same-repo PR with no API key is a secrets-misconfiguration, not an
  # expected skip. Fail loudly so it surfaces during review.
  echo "ERROR: ANTHROPIC_API_KEY is not set in this same-repo PR build." >&2
  echo "The Buildkite secret may be misconfigured. Translation cannot proceed." >&2
  buildkite-agent annotate --style 'error' --context ai-translation-no-key \
    "AI translation FAILED: ANTHROPIC_API_KEY missing in same-repo PR build. Check Buildkite secret configuration." || true
  exit 1
fi

BASE_BRANCH="${BUILDKITE_PULL_REQUEST_BASE_BRANCH:-trunk}"
echo "Comparing against ${BASE_BRANCH} to detect EN string changes…"

git fetch origin "${BASE_BRANCH}" --depth=50

CHANGED_EN=$(git diff --name-only "origin/${BASE_BRANCH}...HEAD" -- \
  'WooCommerce/Resources/en.lproj/Localizable.strings' \
  'WooCommerce/Resources/en.lproj/InfoPlist.strings' | head -n 5)

if [[ -z "${CHANGED_EN}" ]]; then
  echo "Skipping: no EN strings touched on this PR."
  exit 0
fi
echo "EN files changed in this PR:"
echo "${CHANGED_EN}"

# Loop prevention. If the most recent commit is from the bot, the previous
# CI run already produced these translations.
LAST_AUTHOR=$(git log -1 --pretty=format:'%an')
LAST_SUBJECT=$(git log -1 --pretty=format:'%s')
if [[ "${LAST_AUTHOR}" == "${BOT_NAME}" ]] || [[ "${LAST_SUBJECT}" == ${COMMIT_PREFIX}* ]]; then
  echo "Skipping: HEAD is already a translation-bot commit (${LAST_AUTHOR}: ${LAST_SUBJECT})."
  echo "Avoiding CI loop."
  exit 0
fi

# Run the incremental translation across every supported locale.
echo "--- :rocket: Running incremental translation"
bundle exec rake -f fastlane/ai_translation/Rakefile translate:incremental

# If nothing changed on disk, we're done.
if [[ -z "$(git status --porcelain)" ]]; then
  echo "No translation changes produced. Exiting clean."
  exit 0
fi

echo "--- :git: Committing and pushing translations"

git config user.name "${BOT_NAME}"
git config user.email "${BOT_EMAIL}"

# Stage only the resource files; leave anything else (rare) for review.
git add WooCommerce/Resources/*.lproj/Localizable.strings
git add WooCommerce/Resources/*.lproj/InfoPlist.strings

SUMMARY=$(rake -f fastlane/ai_translation/Rakefile translate:report 2>/dev/null | tail -n +5 || true)

git commit -m "${COMMIT_PREFIX} apply AI translations for new/changed strings

Automated by the AI translation pipeline on Buildkite build
${BUILDKITE_BUILD_NUMBER:-unknown}.

${SUMMARY}

Co-Authored-By: WooCommerce Translation Bot <${BOT_EMAIL}>"

git push origin "HEAD:${BUILDKITE_BRANCH}"
echo "Translations pushed to ${BUILDKITE_BRANCH}."
