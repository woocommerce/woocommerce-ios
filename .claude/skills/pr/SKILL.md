---
name: pr
description: Create a pull request following WooCommerce iOS conventions
user-invocable: true
allowed-tools: "Bash, Read, Grep, Glob"
---

Create a pull request following WooCommerce iOS conventions.

Steps:

1. Verify the current branch is not `trunk`:
```bash
git branch --show-current
```

2. Check the diff against trunk:
```bash
git log trunk..HEAD --oneline
git diff trunk...HEAD --stat
```

3. Check non-test diff size (should be under 300 lines):
```bash
git diff trunk...HEAD --stat -- . ':!*Tests*' ':!*Test*' ':!*.generated.*'
```

4. Review the changes to write an accurate description. Read modified files if needed.
   - **Never include actual Linear issue links** (e.g., `https://linear.app/...`) in PR descriptions — Linear is an internal resource. Only reference the issue ID (e.g., `WOOMOB-2485`).

5. Determine if RELEASE-NOTES.txt needs updating. If the change is user-facing, remind about adding a release note entry.

6. Push the branch:
```bash
git push -u origin HEAD
```

7. Create the PR. The description must follow the template in `.github/PULL_REQUEST_TEMPLATE.md`:
```bash
gh pr create --base trunk --title "<concise title>" --body "$(cat <<'EOF'
## Description
<description of changes — why and what>

## Test Steps
<how to test>

## Screenshots
N/A

---
- [ ] I have considered if this change warrants user-facing release notes and have added them to `RELEASE-NOTES.txt` if necessary.
EOF
)"
```

8. **Add labels.** After creating the PR, add all labels in a single call using multiple `--add-label` flags: `gh pr edit <number> --add-label "<label1>" --add-label "<label2>"`. Pick labels from these categories:
   - **Type** (pick one): `type: bug`, `type: crash`, `type: enhancement`, `type: task`, `type: technical debt`, `type: documentation`, `type: question`
   - **Feature** (pick one if applicable): match the changed area to a `feature: *` label (e.g., `feature: POS`, `feature: order list`, `feature: order details`, `feature: product details`, `feature: login`, `feature: dashboard`, `feature: analytics hub`, `feature: coupons`, `feature: shipping labels`, `feature: order creation`, `feature: notifications`, `feature: Blaze`, `feature: CIAB Mobile Experience`, `feature: subscriptions`, `feature: app settings`, etc.)
   - **Priority** (pick one if known): `priority: low`, `priority: medium`, `priority: high`, `priority: critical`
   - **Category** (pick any that apply): `category: accessibility`, `category: design`, `category: performance`, `category: tracks`, `category: unit tests`, `category: ui tests`, `category: tooling`, `category: parity`, `category: i18n`, `category: dark mode`, `category: tablet`, etc.
   - If the feature is behind a flag, also add `status: feature-flagged`
   - Infer labels from the diff and branch name. If unsure about the feature label, ask the user.

9. **Set milestone.** After creating the PR, assign the correct milestone:
   - List open milestones: `gh api repos/woocommerce/woocommerce-ios/milestones --jq '.[] | "\(.title)\t\(.description)"'`
   - Each milestone description contains a `Code Freeze:` date.
   - **If the PR targets `trunk`**: pick the earliest milestone whose code freeze date has **not yet passed** (i.e., the next unfrozen milestone).
   - **If the PR targets a `release/X.Y` branch**: use milestone `X.Y` (the frozen release milestone).
   - Apply with: `gh pr edit <number> --milestone "<milestone title>"`

10. Report the PR URL.

If non-test diff exceeds 300 lines, warn that Danger will flag it and suggest splitting.
