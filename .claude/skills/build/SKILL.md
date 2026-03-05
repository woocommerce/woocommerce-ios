---
name: build
description: Build the WooCommerce iOS project
user-invocable: true
allowed-tools: "Bash, Read, Grep"
---

Build the WooCommerce iOS project.

Run the build command:
```bash
bundle exec fastlane build_for_testing 2>&1 | tail -50
```

If the build fails:
1. Analyze the error output — look for compilation errors, identify file and line
2. Check if it is a missing import, type mismatch, syntax error, or stale generated code
3. If stale codegen, run: `bundle exec rake generate`
4. If `Unable to find a device matching` — use the `/simulator` skill to discover an available simulator, then retry
5. Suggest or apply the fix

If the build succeeds, report success.
