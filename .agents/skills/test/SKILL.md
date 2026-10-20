---
name: test
description: Run tests for WooCommerce iOS (full suite or targeted)
user-invocable: true
allowed-tools: "Bash, Read, Grep, Glob"
argument-hint: "[target] [class] [method]"
---

Run unit tests for the WooCommerce iOS project using the Fastlane `test` lane.

## Run tests

Use `/simulator` to select an available device. Determine scope from $ARGUMENTS:

- **No arguments**: omit `scheme` and `only_testing` to run the lane's full unit test suite.
- **Module**: select its scheme and test target, e.g. `scheme:PointOfSale only_testing:PointOfSaleTests`.
- **Class/method**: add its identifier to `only_testing`, e.g. `WooCommerceTests/MyClass/test_method`.
  Use the module's scheme for module-only changes; use `WooCommerce` for app-target changes.
- **Clean build requested or required to diagnose stale output**: add `clean:true`.

When you need a saved console log, run preparation and the selected command in the same shell:
```bash
set -o pipefail
mkdir -p .agent-artifacts
TASK_ARTIFACTS="$(mktemp -d "$PWD/.agent-artifacts/test.XXXXXX")"
bundle exec fastlane test device:"<simulator-name>" \
  scheme:PointOfSale only_testing:PointOfSaleTests 2>&1 | tee "$TASK_ARTIFACTS/test.log"
```

Check the pipeline exit status before reading excerpts. Retain the full log; a successful `tee`
does not establish that the tests passed.

## After running

1. Report pass/fail counts
2. If failures, show the failing test names and assertion messages
3. Read the failing test files to understand what went wrong
4. Suggest fixes for failing tests

If the simulator is not available, use the `/simulator` skill to discover an available one, then retry.
