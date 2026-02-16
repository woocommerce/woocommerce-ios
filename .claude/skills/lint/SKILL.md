---
name: lint
description: Run SwiftLint on the WooCommerce iOS project
user-invocable: true
allowed-tools: "Bash, Read"
argument-hint: "[--fix]"
---

Run SwiftLint to check for style violations.

If $ARGUMENTS contains "fix" or "autocorrect", run with `--fix`:
```bash
pushd BuildTools && export SDKROOT=$(xcrun --sdk macosx --show-sdk-path) && \
  swift package plugin --allow-writing-to-directory .. \
  --allow-writing-to-package-directory swiftlint --working-directory .. --quiet --fix 2>&1 && popd
```

Otherwise, run check only:
```bash
pushd BuildTools && export SDKROOT=$(xcrun --sdk macosx --show-sdk-path) && \
  swift package plugin --allow-writing-to-directory .. \
  --allow-writing-to-package-directory swiftlint --working-directory .. --quiet 2>&1 && popd
```

After running:
1. Report the number of warnings and errors
2. Group violations by rule name
3. For errors, show file paths and line numbers
4. Suggest manual fixes for issues that autocorrect cannot handle
