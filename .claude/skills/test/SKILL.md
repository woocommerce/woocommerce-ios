---
name: test
description: Run tests for WooCommerce iOS (full suite or targeted)
user-invocable: true
allowed-tools: "Bash, Read, Grep, Glob"
argument-hint: "[target] [class] [method]"
---

Run unit tests for the WooCommerce iOS project using the Fastlane `test` lane.

## Run tests

Determine scope from $ARGUMENTS:

- **No arguments**: Run the full unit test suite:
```bash
bundle exec fastlane test 2>&1 | tail -100
```

- **Module name** (e.g., `Yosemite`, `Networking`, `Storage`) or **test class/method**: Use the `only_testing` option:
```bash
bundle exec fastlane test only_testing:"<Module>Tests[/<ClassName>[/<method>]]" 2>&1 | tail -100
```

- **Clean build requested** (or after dependency/scheme changes): Add `clean:true`:
```bash
bundle exec fastlane test clean:true 2>&1 | tail -100
```

Options can be combined:
```bash
bundle exec fastlane test only_testing:WooCommerceTests/MyClass clean:true 2>&1 | tail -100
```

## After running

1. Report pass/fail counts
2. If failures, show the failing test names and assertion messages
3. Read the failing test files to understand what went wrong
4. Suggest fixes for failing tests

If the simulator `iPhone 16` is not available, discover available simulators:
```bash
xcrun simctl list devices available | grep -E "iPhone [0-9]" | tail -5
```
Then retry with an available iPhone name.
