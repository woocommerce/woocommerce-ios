---
name: debug
description: Debug a failing test or build error in WooCommerce iOS
user-invocable: true
allowed-tools: "Bash, Read, Grep, Glob"
argument-hint: "[test class/method or error description]"
---

Debug a build failure or test failure in the WooCommerce iOS project.

## For Build Failures

1. Run the build and capture errors:
```bash
bundle exec fastlane build_for_testing 2>&1 \
  | grep -E "error:|fatal|cannot find|undefined|ambiguous" | head -30
```

2. Identify the failing file and error type
3. Read the failing file and surrounding context
4. Common root causes in this codebase:
   - **Missing module**: Check Modules/Package.swift target dependencies
   - **Type mismatch**: A Networking model changed — check if Yosemite/Storage need updates
   - **Cannot find type**: May need `bundle exec rake generate` after adding GeneratedCopiable/Fakeable
   - **Ambiguous reference**: Duplicate type names across Networking vs Storage
   - **CoreData model errors**: Check Storage/CoreData/ model versions
5. Propose or apply the fix

## For Test Failures

1. Run the specific failing test (targeted tests require `xcodebuild` directly):
```bash
xcodebuild -workspace WooCommerce.xcworkspace -scheme WooCommerce \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -sdk iphonesimulator test \
  -only-testing:"<target>/<class>/<method>" 2>&1 | tail -50
```

2. Read the test file and understand what it expects
3. Read the implementation file being tested
4. Check the mock class setup
5. Common test failure patterns:
   - **Assertion mismatch**: Verify expected vs actual, check mock stub values
   - **Async timeout**: Check if mock callbacks are being invoked, verify continuation setup
   - **Nil unwrap**: Check if mock return values are configured
   - **Wrong mock state**: Verify spy properties are set correctly
   - **CoreData errors**: Ensure InMemoryStorage is used, not persistent storage
   - **Missing @MainActor**: Some tests need MainActor annotation
6. Propose or apply the fix
