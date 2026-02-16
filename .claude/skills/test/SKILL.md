---
name: test
description: Run tests for WooCommerce iOS (full suite or targeted)
user-invocable: true
allowed-tools: "Bash, Read, Grep, Glob"
argument-hint: "[target] [class] [method]"
---

Run unit tests for the WooCommerce iOS project. Determine scope from $ARGUMENTS:

- **No arguments**: Run the full test suite
- **Module name** (e.g., `Yosemite`, `Networking`, `Storage`): Run that module's tests with `-only-testing:"<Module>Tests"`
- **Test class name**: Run only that class with `-only-testing:"WooCommerceTests/<ClassName>"`
- **Test method name**: Run only that method with `-only-testing:"WooCommerceTests/<ClassName>/<method>"`

Base command:
```bash
xcodebuild -workspace WooCommerce.xcworkspace -scheme WooCommerce \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -sdk iphonesimulator -configuration Debug build test \
  [-only-testing:"<target>"] 2>&1 | tail -100
```

After running:
1. Report pass/fail counts
2. If failures, show the failing test names and assertion messages
3. Read the failing test files to understand what went wrong
4. Suggest fixes for failing tests

If the simulator `iPhone 16` is not available, try `iPhone 15` or `iPhone 16 Pro`.
