---
name: bootstrap
description: Install dependencies and build tools for WooCommerce iOS
user-invocable: true
allowed-tools: "Bash, Read"
---

Bootstrap the local environment for WooCommerce iOS.

First, ensure the correct Ruby version is installed and active:
```bash
ruby --version        # should match the version in .ruby-version
rvm install ruby-$(cat .ruby-version)   # installs if missing, no-op if already present
rvm use ruby-$(cat .ruby-version)       # activate
```

Then run the dependency install command:
```bash
bundle install && bundle exec rake dependencies
```

If the command fails:
1. Report the failing step and error output
2. If `Bundler::GemNotFound` or wrong Ruby version errors appear, run `rvm use ruby-$(cat .ruby-version)` and retry
3. If `configure_apply` (fastlane credentials) fails with exit 128, this is a git-crypt/mobile-secrets issue — it does not block building or testing, only internal credentials are missing
