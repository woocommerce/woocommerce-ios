---
name: build
description: Build the WooCommerce iOS project
user-invocable: true
allowed-tools: "Bash, Read, Grep"
---

Build the WooCommerce iOS project.

Run the build command:
```bash
bundle exec rake build 2>&1 | tail -50
```

If the build fails:
1. Analyze the error output — look for compilation errors, identify file and line
2. Check if it is a missing import, type mismatch, syntax error, or stale generated code
3. If stale codegen, run: `bundle exec rake generate`
4. If `Unable to find a device matching` — run `xcrun simctl list devices available | grep -E "iPhone [0-9]" | tail -5` to find an available simulator name, then retry
5. Suggest or apply the fix

If the build succeeds, report success.
