---
name: test
description: Run tests for WooCommerce iOS (full suite or targeted)
user-invocable: true
allowed-tools: "Bash, Read, Grep, Glob"
argument-hint: "[target] [class] [method]"
---

Run unit tests for the WooCommerce iOS project. Determine scope from $ARGUMENTS:

- **No arguments**: Run the full test suite using rake:
```bash
bundle exec rake test 2>&1 | tail -100
```

- **Module name** (e.g., `Yosemite`, `Networking`, `Storage`): Run that module's tests:
```bash
xcodebuild -workspace WooCommerce.xcworkspace -scheme WooCommerce \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -sdk iphonesimulator test -only-testing:"<Module>Tests" 2>&1 | tail -100
```

- **Test class or method**: Run targeted tests:
```bash
xcodebuild -workspace WooCommerce.xcworkspace -scheme WooCommerce \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -sdk iphonesimulator test \
  -only-testing:"WooCommerceTests/<ClassName>[/<method>]" 2>&1 | tail -100
```

After running:
1. Report pass/fail counts
2. If failures, show the failing test names and assertion messages
3. Read the failing test files to understand what went wrong
4. Suggest fixes for failing tests

If the simulator `iPhone 16` is not available, discover available simulators:
```bash
xcrun simctl list devices available | grep -E "iPhone [0-9]" | tail -5
```
Then retry with an available iPhone name.
