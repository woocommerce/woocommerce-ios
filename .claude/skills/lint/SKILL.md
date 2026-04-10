---
name: lint
description: Run SwiftLint on the WooCommerce iOS project
user-invocable: true
allowed-tools: "Bash, Read"
argument-hint: "[--fix]"
---

Run SwiftLint to check for style violations.

If $ARGUMENTS contains "fix" or "autocorrect":
```bash
bundle exec rake lint:autocorrect
```

Otherwise, run check only:
```bash
bundle exec rake lint
```

After running:
1. Report the number of warnings and errors
2. Group violations by rule name
3. For errors, show file paths and line numbers
4. Suggest manual fixes for issues that autocorrect cannot handle
