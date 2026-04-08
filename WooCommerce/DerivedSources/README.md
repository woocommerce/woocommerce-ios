# Derived Sources

This folder contains files generated at build time by the `GenerateCredentials` aggregate target.
You'll notice the setup derived sources are set up differently in the Xcode project, that is, as a group rather than the superior synchronized folder.
This is because synchronized folders determine their file list at project-load time, before build phases run.
Generated files that don't exist on disk yet would be invisible to a synchronized group.

The generation script (`Scripts/build-phases/generate-credentials.sh`) creates `ApiCredentials.swift` in each subfolder:

- `WooCommerce/` — compiled by the WooCommerce app target
- `WatchApp/` — compiled by the Woo Watch App target

These files are **gitignored** and must not be committed.
They are recreated on every build from either the secrets file (`~/.configure/woocommerce-ios/secrets/woo_app_credentials.json`) or a placeholder template.
