---
name: self-heal
description: Pick one unhandled production crash from Sentry, claim it with a GitHub issue, and prove a fix with a red/green draft PR validated on Buildkite. Use when asked to "self-heal", "fix a production crash", or when run on a loop.
user-invocable: true
allowed-tools: "Bash, Read, Edit, Write, Grep, Glob"
---

One run advances the oldest open self-heal PR that is ready, then claims at most one new crash.
Runs start with no memory of earlier runs: GitHub, Buildkite and `$LOG` are the only state.
Work in the runner worktree, never in the checkout that holds this skill:

```bash
SELF_HEAL=~/Developer/git-worktrees/wcios/self-heal-prototype/.agents/skills/self-heal
RUNNER=~/Developer/git-worktrees/wcios/self-heal-runner
CRASHES="$SELF_HEAL/Scripts/sentry-crashes"
CLAIMS="$SELF_HEAL/Scripts/claim-check"
LOG=~/.self-heal/runs.log
```

If `$RUNNER` does not exist, create it from `origin/trunk` and bootstrap it (`bundle install && bundle exec rake dependencies`).
Leave `$RUNNER` clean at the end of every run: commit or `git stash` work in progress, switch back to the detached `origin/trunk`, and delete local branches that have no PR.

Log every phase as one line to `$LOG`: `<ISO time> <phase> <WOOCOMMERCE-IOS-id or -> <one-line outcome>`.
The log calibrates the loop interval, so log `start` and `end` even when the run stops early.

Every issue body and PR description carries this trailer, after the content and before any attribution or template checklist (one `---` serves both trailer and attribution):

```markdown
---

This is part of an experiment I'm running in building custom tooling for self-healing.
```

The `Status:` line in the issue body is the crash's current state.
Whenever it changes, edit the body in place (`gh issue edit --body-file`); comment only when there is something to explain, such as a diagnosis or a build link.

## Privacy

Crash data reaches you only through `$CRASHES`, which drops user data and replaces literals with placeholders.
Never query Sentry another way, and never copy breadcrumbs, user, tags or request data into anything.
Before posting any issue, comment, PR or commit, pipe the text through `$CRASHES redact` and diff it against the original.
Allowed differences: Sentry and GitHub links, issue and PR numbers, source line numbers, and app versions such as `25.9.0.4`.
Rephrase code literals you wrote yourself rather than quoting them.

## 1. Tend open work first

List open self-heal PRs:

```bash
gh pr list --author @me --state open --json number,headRefName,headRefOid,statusCheckRollup \
  --jq '[.[] | select(.headRefName | startswith("self-heal/"))]'
```

Advance the oldest PR that has a finished Buildkite build on its head commit:

- Red commit, build failed on the new test → red proven: link the build in the PR, push the fix commit (step 5.4).
- Red commit, build failed elsewhere or the new test passed → the proof is wrong: fix the test or abandon (step 5 fallback).
- Fix commit, build passed → green proven: link the build in the PR, update the issue to `Status: PR #<n> ready for review`.
- Fix commit, build failed → fix it on the branch.

Soft-failed steps count only if the PR caused them: compare with the same step on a recent trunk build.

Then continue to step 2 if fewer than 5 self-heal PRs are open; otherwise log `cap` and stop.

## 2. Pick a crash

1. `$CRASHES releases` → take the two most recent `X.Y` versions; use the older as `--min-version`.
2. `$CRASHES list --min-version <X.Y>` → candidates by frequency.
3. Skip a candidate if `$CLAIMS <id> <shortId>` prints anything: an issue or PR on GitHub, or a Linear issue, already names it.
4. Prefer crashes with in-app frames (`$CRASHES event <id>`, frames with `binary: "WooCommerce"` or `inApp: true`).
   Skip crashes that live entirely in Apple or third-party frameworks unless an app frame or the exception message names our code.
5. Skip a candidate whose repeating in-app frames match an open `type: crash` issue (`gh issue list --label "type: crash" --state open`): the top frame of a stack overflow differs from crash to crash.
   Add its short ID to that issue's body instead, so `$CLAIMS` finds it next time.
6. Skip races between threads inside a framework (two threads in the same library at the crash, no app frame between them): a unit test cannot reproduce them.

No candidate left: lower `--min-version` by one release and repeat, going back at most four releases. Still none: log `dry` and stop.

## 3. Claim it

Create the issue before reading any code — the issue is the lock:

```bash
gh issue create --title "Crash: <shortId> <redacted title>" --label "type: crash" --body-file <file>
```

Body: Sentry permalink, event and user counts, release range, the redacted exception and top in-app frames, `Status: investigating`, the experiment line, and the closing line `*Posted by Claude Code (<model>) on behalf of @mokagio with approval.*`

## 4. Diagnose

In `$RUNNER`: `git fetch origin && git switch -c self-heal/<shortId-lowercased> origin/trunk`.

Read the whole crashed thread (`$CRASHES event <id>`), not just its top frames or Sentry's culprit.
Stack overflows and watchdog kills blame whatever frame was running last; the cause is the repeating pattern further down.
Then read the code at the crash frames, at the release tag the crash comes from (`git show <tag>:<path>`, line numbers shift) and on trunk.
If trunk already fixed it, comment with the commit, close the issue as completed, and stop.

Do not touch, and stop if a fix would need to touch:

- `WooCommerce/Classes/Authentication/`, `Modules/Sources/Hardware/`, `Modules/Sources/PointOfSale/Card Present Payments/`
- Core Data models (`*.xcdatamodeld`) and migrations
- `fastlane/`, `.buildkite/`, `Gemfile*`, `Package.resolved`

Comment the diagnosis and which path it would touch on the issue, set `Status: needs human`, and stop.

## 5. Prove it red, then green

Fix like a senior developer: never trade a crash for a silent wrong answer.

1. If needed, commit a behaviour-preserving extraction that makes the crashing code testable.
2. Commit the test that reproduces the production signature, following `.agents/rules/testing.md`. Run it locally and confirm it fails for the crash's reason.
3. Push and open a **draft** PR (see below), then stop the run. A later run checks that Buildkite's Unit Tests step failed on that test — the red proof.
4. When red is proven: commit the fix, run the affected tests locally, push, and stop. A later run checks the build passes — the green proof.

If you cannot write a reproducing test: add instrumentation that would confirm the cause, or a testable refactor, with a prediction to check on a later run.
If neither is possible, comment the diagnosis on the issue, leave it open with `Status: needs human`, and stop.

## 6. The PR

Follow `/pr` for the body template, labels (`type: crash` plus a feature label) and milestone, with these differences:

- Draft, title `Fix crash <shortId>: <short description>`, body links the issue with `Fixes #<n>`.
- Description says what crashed, why, how the red build proves the cause, and how the green build proves the fix.
- No mention of AI in commits or the description (repo rule); the issue carries the attribution.

Update the issue to `Status: PR #<n> awaiting red build`, log `end`, and stop. Never mark a PR ready or merge it.
