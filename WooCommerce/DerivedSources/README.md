# Derived Sources

This folder contains files generated at build time by the `GenerateCredentials` aggregate target.

The generation script (`Scripts/build-phases/generate-credentials.sh`) creates `ApiCredentials.swift` in each subfolder:

- `WooCommerce/` — compiled by the WooCommerce app target
- `WatchApp/` — compiled by the Woo Watch App target

These files are **gitignored** and must not be committed.
They are recreated on every build from either the secrets file (`~/.configure/woocommerce-ios/secrets/woo_app_credentials.json`) or a placeholder template.

The subfolders use explicit Xcode groups (not synchronized folders) because synchronized folders determine their file list at project-load time, before build phases run.
Generated files that don't exist on disk yet would be invisible to a synchronized group.
