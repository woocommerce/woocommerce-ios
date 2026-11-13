---
name: build
description: Build the WooCommerce iOS project
user-invocable: true
allowed-tools: "Bash, Read, Grep"
---

Build the WooCommerce iOS project.

Use `/simulator` to select an available device. Run the build with that device's name:
```bash
bundle exec fastlane build_for_testing device:"<simulator-name>"
```

When you need a saved console log, use this variant instead:
```bash
set -o pipefail
mkdir -p .agent-artifacts
TASK_ARTIFACTS="$(mktemp -d "$PWD/.agent-artifacts/build.XXXXXX")"
printf 'Task artifacts: %s\n' "$TASK_ARTIFACTS"
bundle exec fastlane build_for_testing device:"<simulator-name>" 2>&1 | tee "$TASK_ARTIFACTS/build.log"
```
Check the pipeline exit status before reporting success. Keep the full log in the task artifact directory.
Use the same destination and build products for installation. An installed app may require
frameworks from that build; follow `.agents/rules/verification.md` if launch fails.

If the build fails:
1. Analyze the error output — look for compilation errors, identify file and line
2. Check if it is a missing import, type mismatch, syntax error, or stale generated code
3. If stale codegen, run: `bundle exec rake generate`
4. If `Unable to find a device matching` — use the `/simulator` skill to discover an available simulator, then retry
5. Suggest or apply the fix

If the build succeeds, report success.
