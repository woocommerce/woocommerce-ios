# Pull Request Conventions

Based on `CONTRIBUTING.md` and `.github/PULL_REQUEST_TEMPLATE.md`.

## Branch Naming
- Feature: `WOOMOB-XXXX-short-description`
- Alternative: `issue/XXXX-short-description`
- Base branch: `trunk`

## PR Requirements
- 1 reviewer approval required
- Must have at least one label
- Must have a milestone (unless labeled `milestone-not-required` or `status: feature-flagged`)
- Non-test diff should be under 300 lines (enforced by Danger)

## PR Description Format
```markdown
## Description
Brief description of the changes — why is it needed, what does it do.

## Test Steps
Describe how to test. Outline the main user flow rather than every tap.
Mention key devices, scenarios, or edge cases to verify.

## Screenshots
Include before/after images or gifs when appropriate.

---
- [ ] I have considered if this change warrants user-facing release notes and have added them to `RELEASE-NOTES.txt` if necessary.
```

## Merge Policy
- Use merge commits (not squash)
- PR author merges their own PR after approval

## RELEASE-NOTES.txt
If the change is user-facing or internal-notable, add an entry:
```
- [*] Short description [PR_URL]
- [Internal] Internal change description [PR_URL]
```
Priority: `[*]` normal, `[**]` high, `[***]` critical.

## Commit Messages
- Start with a capitalized verb: Add, Fix, Update, Remove, Refactor, Implement
- Concise single line, no period at end
- Examples: `Add push notification support`, `Fix product type filters issue`
