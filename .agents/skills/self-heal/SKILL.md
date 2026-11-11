---
name: self-heal
description: Pick one unhandled production crash from Sentry (or, when none qualify, a reported GitHub bug), prove it with a red validation PR on Buildkite, and fix it in a draft PR that turns the test green. Use when asked to "self-heal", "fix a production crash", or when run on a loop.
user-invocable: true
allowed-tools: "Bash, Read, Edit, Write, Grep, Glob"
---

Each crash moves through three artifacts: an issue (the claim), a validation PR (the red proof, closed once Buildkite confirms it), and a fix PR (the test plus the fix, green).
An issue with a red proof and no fix PR yet is a brief: everything a fix needs, waiting for a fix slot.
Fix PRs are capped because they ask reviewers for time; briefs have their own cap, so research continues while the fix slots are full.
One run tends open work, then either turns one brief into a fix PR or claims at most one new crash.
Runs start with no memory of earlier runs: GitHub, Buildkite and `$LOG` are the only state.
Work in the runner worktree, never in the checkout that holds this skill:

```bash
SELF_HEAL=~/Developer/git-worktrees/wcios/self-heal-prototype/.agents/skills/self-heal
RUNNER=~/Developer/git-worktrees/wcios/self-heal-runner
CRASHES="$SELF_HEAL/Scripts/sentry-crashes"
CLAIMS="$SELF_HEAL/Scripts/claim-check"
CAP="$SELF_HEAL/Scripts/cap"
LOG=~/.self-heal/runs.log
```

If `$RUNNER` does not exist, create it from `origin/trunk` and bootstrap it (`bundle install && bundle exec rake dependencies`).
Leave `$RUNNER` clean at the end of every run: commit or `git stash` work in progress, switch back to the detached `origin/trunk`, and delete local branches that have no open PR.

Log every phase as one line to `$LOG`: `<ISO time> <phase> <WOOCOMMERCE-IOS-id or -> <one-line outcome>`.
The log calibrates the loop interval, so log `start` and `end` even when the run stops early.

Every issue body and PR description carries this trailer, after the content and before any attribution or template checklist (one `---` serves both trailer and attribution):

```markdown
---

This is part of an experiment I'm running in building custom tooling for self-healing.
```

No commit or PR mentions AI (repo rule), validation PRs included: drop any generated-with footer. Issues and comments carry the attribution.

The `Status:` line in the issue body is the crash's current state.
Whenever it changes, edit the body in place (`gh issue edit --body-file`); comment only when there is something to explain, such as a diagnosis or a build link.
On an issue someone else opened (step 2b), the `Status:` line lives in your latest comment instead: change it with `gh issue comment <n> --edit-last`.

## Privacy

Crash data reaches you only through `$CRASHES`, which drops user data and replaces literals with placeholders.
Never query Sentry another way, and never copy breadcrumbs, user, tags or request data into anything.
Before posting any issue, comment, PR or commit, pipe the text through `$CRASHES redact` and diff it against the original.
Allowed differences: Sentry and GitHub links, issue and PR numbers, source line numbers, and app versions such as `25.9.0.4`.
Rephrase code literals you wrote yourself rather than quoting them.

## 1. Tend open work first

List open self-heal PRs and issues:

```bash
gh pr list --author @me --state open --json number,title,headRefName,headRefOid,statusCheckRollup \
  --jq '[.[] | select(.headRefName | startswith("self-heal/"))]'
gh issue list --author @me --label "type: crash" --state open --json number,title
```

Validation PRs have branches ending in `-red`; every other `self-heal/` branch is a fix PR.
For each PR with a finished Buildkite build on its head commit:

- Validation PR, build failed on the new test → red proven.
  Comment the build link on the issue, set `Status: red proven, fix PR pending`, and close the validation PR with a one-line comment linking the issue.
  The issue is now a brief.
- Validation PR, build failed elsewhere or the new test passed → the proof is wrong: fix the test on the branch, or close the PR and fall back (step 5).
- Fix PR, build passed → green proven: link the build in the PR, set the issue to `Status: PR #<n> ready for review`.
- Fix PR, build failed → fix it on the branch.

Soft-failed steps count only if the PR caused them: compare with the same step on the latest trunk build, by total and by file.

Then answer the conversation on every open self-heal PR and issue, including bot comments such as Danger's, which are edited in place:

- PRs: `gh pr view <n> --json comments,reviews` and `gh api repos/{owner}/{repo}/pulls/<n>/comments`.
- Issues: `gh issue view <n> --json comments,labels`.

Anything updated after your last reply needs a fix (push to the branch, add the requested label) or one reply saying why no change is needed, with the evidence, such as the trunk build link.
Replies follow the privacy rules and end with the experiment trailer and the attribution line.
Never resolve review threads; the reviewer does that.

Then run `$CAP status` and take the first that applies:

1. `fix-slot free` and a brief is at `Status: red proven, fix PR pending` → fix the oldest one (step 6).
2. `brief-slot free` → research a new one (step 2).
3. Otherwise log `cap` and stop.

Never run `$CAP reset`: it is the operator's way to stop the fix PRs open now counting toward the cap, without closing them.

## 2. Pick a crash

1. `$CRASHES releases` → take the two most recent `X.Y` versions; use the older as `--min-version`.
2. `$CRASHES list --min-version <X.Y>` → candidates by frequency.
3. Skip a candidate below the impact threshold: it needs `userCount` of at least 5, or a `count` of at least 10.
   One user crashing ten times counts; one user crashing once does not.
4. Skip a candidate if `$CLAIMS <id> <shortId>` prints anything: an issue or PR on GitHub, or a Linear issue, already names it.
5. Prefer crashes with in-app frames (`$CRASHES event <id>`, frames with `binary: "WooCommerce"` or `inApp: true`).
   Skip crashes that live entirely in Apple or third-party frameworks unless an app frame or the exception message names our code.
6. Skip a candidate whose repeating in-app frames match an open `type: crash` issue: the top frame of a stack overflow differs from crash to crash.
   Add its short ID to that issue's body instead, so `$CLAIMS` finds it next time.
7. Skip races between threads inside a framework (two threads in the same library at the crash, no app frame between them): a unit test cannot reproduce them.
8. Skip a candidate trunk has likely fixed. For each in-app file in the crashed thread, read `git log <release-tag>..origin/trunk -- <file>` in `$RUNNER`, and read any commit that touches the crashing function.
   Skip, logging `fixed-on-trunk` with the commit, if one guards the crashing path, especially when Sentry has no events for the crash from releases that include that commit.

No candidate left: log `dry` and look for a reported bug instead (step 2b).
Do not widen to older releases or lower the threshold: older releases only add crashes that stopped, and smaller ones are not worth a reviewer's time.

## 2b. Pick a reported bug

List open issues someone else opened, oldest first, skipping `type: crash` and feature requests (`Enhancement`, `type: enhancement`):

```bash
gh issue list --state open --limit 500 --json number,title,author,labels,createdAt,comments
```

Skip an issue that already has a comment from you, an open PR referencing it, or a line in `$LOG` naming it (`#<n>`).
Read the report and its comments, and the code it points at on trunk.
Skip, logging `unverifiable #<n>` with the reason, if a unit test cannot reproduce it: it needs a device, a specific store's data, a server bug, or only UI rendering.

No issue left: log `dry` and stop.

Take the first that can be reproduced to step 4, using `<n>` as the ID: branches `self-heal/issue-<n>-red` and `self-heal/issue-<n>`, titles `Validate #<n>: ...` and `Fix #<n>: ...`.
Do not open a new issue (step 3).
The claim is the comment the validation PR leads to: post it once the red build is proven, never before, so a failed attempt leaves nothing on someone else's issue.
It says what the test reproduces, links the red build, and ends with `Status: red proven, fix PR pending`, the experiment trailer, and the attribution line.

## 3. Claim it

Runs never overlap, so the read-only checks in step 2 are safe before claiming. Create the issue before changing any code:

```bash
gh issue create --title "Crash: <shortId> <redacted title>" --label "type: crash" --label "feature: <area>" --body-file <file>
```

Pick the feature label from `gh label list --search "feature:"` by the code the crash runs through; Danger asks for one.
Body: Sentry permalink, event and user counts, release range, the redacted exception and top in-app frames, `Status: investigating`, the experiment trailer, and the closing line `*Posted by Claude Code (<model>) on behalf of @mokagio with approval.*`

## 4. Diagnose

In `$RUNNER`: `git fetch origin && git switch -c self-heal/<shortId-lowercased>-red origin/trunk`.
For a reported bug, skip what is crash-specific below (the stack, the release tag) and read the report instead.

Read the whole crashed thread (`$CRASHES event <id>`), not just its top frames or Sentry's culprit.
Stack overflows and watchdog kills blame whatever frame was running last; the cause is the repeating pattern further down.
Then read the code at the crash frames, at the release tag the crash comes from (`git show <tag>:<path>`, line numbers shift) and on trunk.
If trunk turns out to have fixed it after all, comment with the commit, close the issue as completed, log `missed-pre-claim`, and stop: step 2.8 should have caught it.

Do not touch, and stop if a fix would need to touch:

- `WooCommerce/Classes/Authentication/`, `Modules/Sources/Hardware/`, `Modules/Sources/PointOfSale/Card Present Payments/`
- Core Data models (`*.xcdatamodeld`) and migrations
- `fastlane/`, `.buildkite/`, `Gemfile*`, `Package.resolved`

Comment the diagnosis and which path it would touch on the issue, set `Status: needs human`, and stop.

## 5. Prove it red

1. If needed, commit a behaviour-preserving extraction that makes the crashing code testable.
2. Commit the test that reproduces the production signature, following `.agents/rules/testing.md`.
   Write it in Swift Testing (`@Test`, `#expect`). When the code under test only has an XCTest class, put the test in a new Swift Testing file next to it rather than adding to that class.
   Keep it fast and deterministic: no sleeps, and no stress loops beyond what reproduces the crash.
3. Run it locally and confirm it fails for the crash's reason. Do not push a red proof you have not seen fail.
4. Push and open the validation PR: draft, assigned to @mokagio, label `type: crash` (`type: bug` for a reported bug), title `Validate crash <shortId>: <short description>`.
   Body: a link to the issue (`Part of #<n>`, never `Fixes`), what the test reproduces, that the PR exists only for the red build and will be closed without merging, and the experiment trailer.
5. Set the issue to `Status: validation PR #<n> awaiting red build` (for a reported bug, leave the issue alone until red is proven), log `end`, and stop.

If you cannot write a reproducing test: add instrumentation that would confirm the cause, or a testable refactor, with a prediction to check on a later run.
If neither is possible, comment the diagnosis on the issue, leave it open with `Status: needs human`, and stop.

## 6. Fix it green

Once red is proven, in `$RUNNER`: `git switch -c self-heal/<shortId-lowercased> origin/trunk`, cherry-pick the validation branch's commits, and commit the fix on top.
Fix like a senior developer: never trade a crash for a silent wrong answer.
Run the affected tests locally, push, and open the fix PR.

Follow `/pr` for the body template, labels (`type: crash` plus the issue's feature label) and milestone, with these differences:

- Draft, assigned to @mokagio, title `Fix crash <shortId>: <short description>`, body links the issue with `Fixes #<n>`.
- Description says what crashed, why, and links the red build from the validation PR; the green build proves the fix.
- A **Keep or delete the test** section: the test proved this crash and guards against its return, but if it costs more to maintain than it protects, the reviewer can drop it.
  Name the test and include a ready-to-paste prompt, e.g. ``Remove `<test name>` from `<file>` and any helpers only it uses, then run the tests.``
Set the issue to `Status: PR #<n> awaiting green build`, log `end`, and stop. Never mark a PR ready or merge it.
