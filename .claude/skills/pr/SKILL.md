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

8. Report the PR URL.

If non-test diff exceeds 300 lines, warn that Danger will flag it and suggest splitting.
