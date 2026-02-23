---
name: bootstrap
description: Install dependencies and build tools for WooCommerce iOS
user-invocable: true
allowed-tools: "Bash, Read"
---

Bootstrap the local environment for WooCommerce iOS.

First, check the required Xcode version and select it if available:
```bash
cat .xcode-version   # check required version
xcode-select -p      # check currently selected Xcode
```
If the selected Xcode doesn't match, look for the required version under `/Applications/` and switch to it via `xcode-select -s <path>`. If it's not installed, note this to the user and proceed with the currently selected Xcode.

Then, ensure the correct Ruby version is active. The required version is in `.ruby-version`.
Detect which Ruby version manager is available and use it:
- `rvm`: `rvm install ruby-$(cat .ruby-version) && rvm use ruby-$(cat .ruby-version)`
- `rbenv`: `rbenv install $(cat .ruby-version) && rbenv local $(cat .ruby-version)`
- `chruby` / `mise`: activate the version from `.ruby-version` using the appropriate command

Verify with `ruby --version` before proceeding.

Then run the dependency install command:
```bash
bundle install && bundle exec rake dependencies
```

If the command fails:
1. Report the failing step and error output
2. If `Bundler::GemNotFound` or wrong Ruby version errors appear, ensure the correct Ruby version is active and retry
3. If `configure_apply` (fastlane credentials) fails with exit 128, this is a git-crypt/mobile-secrets issue — it does not block building or testing, only internal credentials are missing
