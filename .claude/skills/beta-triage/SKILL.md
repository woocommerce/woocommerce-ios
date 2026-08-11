---
name: beta-triage
description: Triage a release milestone's PRs by existing test evidence and produce a focused beta-testing plan (flows + P2 draft) for the Peacock beta-testing rotation
user-invocable: true
allowed-tools: "Bash, Read, Write, Agent, Grep, Glob"
---

Produce an evidence-based beta-testing plan for a release version, for the Peacock
beta-testing rotation (~1–2 hours per platform, both platforms, on beta builds).

The goal of the rotation: catch the bugs that per-PR testing structurally cannot —
real release builds, real devices and stores, all changes integrated, fresh
cross-platform eyes — before merchants do. Therefore: do NOT plan to re-test what
was already verified during PR review. Spend the timebox exclusively on changes
without prior real-world verification.

## Input

The argument is the release version, e.g. `25.3`. If missing, ask for it.

Team author allowlist (edit as the team changes):
`toupper joshheald malinajirka kidinov samiuelson iamgabrielma`

## Steps

### 1. Collect milestone PRs from both repos

Milestone titles may carry decorations (e.g. `25.3 ❄️` for a frozen milestone), so
resolve the real title first:

```bash
gh api "repos/woocommerce/woocommerce-ios/milestones?state=all&per_page=100" -q '.[].title' | grep "<version>"
gh api "repos/woocommerce/woocommerce-android/milestones?state=all&per_page=100" -q '.[].title' | grep "<version>"
```

Then list all PRs per repo (single query per repo, filter authors locally — do not
run one search per author, it misses nothing and this is cheaper):

```bash
gh pr list --repo woocommerce/woocommerce-ios --state all --limit 400 \
  --search 'milestone:"<resolved title>"' \
  --json number,title,url,author,state
```

Keep only PRs whose author is in the allowlist. Track MERGED separately from
CLOSED-unmerged (the latter are excluded from the plan but listed in the report so
nothing disappears silently).

### 2. Scan each PR for testing evidence

Fan out one subagent per repo (parallel, structured output). For each PR the agent
inspects `gh pr view <num> --json title,body,reviews,comments` and classifies:

- **Author testing**: device / simulator-or-emulator / unit-tests-only / none.
  Screenshots, videos, or explicit "tested on…" statements count; test steps alone
  do NOT count as evidence.
- **Reviewer testing**: did any reviewer state they ran the change ("tested on my
  device", "works as expected" after steps, own screenshots)? An approval or "LGTM"
  alone is code review, not testing.
- **Gaps**, especially these known patterns:
  - entitlement/hardware only available post-merge (e.g. Tap to Pay entitlement
    missing from alpha builds → TestFlight is the first real test)
  - speculative fix nobody could reproduce (typically crash fixes) → beta
    verification happens in Sentry, not by tapping
  - feature-flag gating: check whether the flag is enabled in beta/release builds;
    if dev/alpha-only, the code is unreachable in beta
  - store/environment prerequisites (specific Woo version, multi-currency, RTL
    locale, Stripe account state, plugin/extension required)
  - edge-case fix pushed late in review with no recorded re-test
  - "will verify in beta" or "couldn't test X" statements
- **Supersede chains**: if the PR re-lands another PR (body/comments say
  "superseded by/from #NNNN"), fetch the original — review and testing evidence
  there counts for the re-land.

### 3. Classify every merged PR

- ✅ **Verified in review** — author evidence of the real flow, and/or reviewer
  tested. Skip in beta; list with a one-line justification.
- 🎯 **Needs beta test** — the specific user-facing scenario was never run by
  anyone, and it IS reachable in a beta build.
- 📊 **Sentry watch** — speculative crash fix; monitoring, not manual testing.
- 🚫 **Unreachable in beta** — flag-gated off in beta/release builds. Note it must
  be tested in the beta of whichever release enables the flag.
- ⏭️ **Not beta-testable** — internal-only (tests, tooling, docs, dead-code/flag
  removal, changelog), analytics-only (verify in Tracks), or requires equipment a
  beta tester won't have (network proxy, unavailable account states → best-effort).

When unsure between ✅ and 🎯, prefer 🎯 with a short reason — false positives cost
minutes, false negatives ship bugs.

### 4. Collapse 🎯 PRs into flows

Group related PRs (stacks, same feature area) into single test flows — one flow can
cover many PRs. Each flow is one line: platform, concrete steps, PR link(s), and a
terse *why* (what makes it unverified). Order by risk. The full list must fit the
rotation timebox: ~1–2 h per platform. If it doesn't fit, cut the flows whose gap
is smallest and move them to ✅/best-effort with a note.

Tag each flow by who can run it:

- 🤖 **Agent-verifiable** — reachable on a simulator with no hardware, entitlement,
  or special store prerequisite (layout/Dynamic Type checks, crash-gesture spot
  checks, RTL visual passes, navigation flows). These can be pre-cleared with the
  `/verify` skill (mobile-mcp simulator loop); offer to run it for the iOS ones.
  A simulator pass is strong but not identical to a beta build — note any flow
  where release-build config could matter and keep those 🧑.
- 🧑 **Human-only** — needs real hardware (card readers, Tap to Pay), a real store
  state, a physical device, or the actual TestFlight/Play beta build.

### 5. Output

Produce two things in chat (do not post anywhere):

1. **The flow checklist** — one-liners, for the tester to execute.
2. **A P2 draft post** for the beta-testing report, structured as:
   - intro: triage method + timebox, milestones covered
   - priority flows table (flow / platform / steps / PRs / result placeholder —
     leave results BLANK for the tester to fill in; never pre-fill outcomes)
   - Sentry-watch section
   - "Verified in PR review — not re-tested" section with one-line justifications
   - store/device prerequisites the tester may lack, with the instruction to move
     those rows to "not re-tested + reason" rather than dropping them silently

Style: plain language, short, no em-dashes (see the team's PR-description
conventions). Do not @-mention anyone.

## Notes

- CLOSED-unmerged PRs in the milestone: mention in the report as excluded.
- Bot PRs (dependabot, wpmobilebot release merges) are always ⏭️.
- If a `needs-beta-testing` label exists on PRs, treat labeled PRs as 🎯
  automatically and say the label drove the classification.
