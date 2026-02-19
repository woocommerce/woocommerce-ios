---
name: bootstrap
description: Install dependencies and build tools for WooCommerce iOS
user-invocable: true
allowed-tools: "Bash, Read"
---

Bootstrap the local environment for WooCommerce iOS.

Run the dependency install command:
```bash
bundle install && bundle exec rake dependencies
```

If the command fails:
1. Report the failing step and error output
2. Check whether Ruby version matches `.ruby-version`
3. Remind that Xcode 14+ is required
