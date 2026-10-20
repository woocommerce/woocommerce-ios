---
name: review
description: Review code changes against WooCommerce iOS standards
user-invocable: true
allowed-tools: "Bash, Read, Grep, Glob"
---

Review the current changes for compliance with WooCommerce iOS conventions.

1. Get the changes to review:
```bash
git diff trunk...HEAD
```
If no diff against trunk, fall back to staged changes: `git diff --cached`

2. Check each modified file against these criteria:

**Architecture** (see `.claude/rules/architecture.md`):
- UI code does not import Networking or Storage directly
- New actions follow the Yosemite dispatch pattern
- Dependencies injected via constructor with protocol types
- Coordinators for navigation, ViewModels for state

**Swift Style** (see `.claude/rules/swift-style.md`):
- No force unwraps or force casts
- Error handling uses do-catch, not try?
- Line length under 163 characters
- No parentheses around conditionals

**Localization** (see `.claude/rules/localization.md`):
- NSLocalizedString uses reverse-DNS keys with value: and comment:
- No LocalizedStringKey
- No string interpolation in localized strings
- Positional placeholders (%1$@)
- Strings grouped in enum Localization { }

**Analytics** (see `.claude/rules/analytics.md`):
- New events added to WooAnalyticsStat
- Properties use WooAnalyticsEvent factory pattern
- Analytics dependency injected

**Testing** (see `.claude/rules/testing.md`):
- New code has corresponding tests
- Tests use snake_case naming
- Given/When/Then structure
- Hand-written mocks with Mock prefix

3. Report findings organized by severity:
   - **Blockers**: Must be fixed before merge
   - **Suggestions**: Recommended improvements
   - **Positives**: Things done well
