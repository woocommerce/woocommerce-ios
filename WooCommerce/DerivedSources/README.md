# DerivedSources

Xcode shows two `ApiCredentials.swift` entries in the project navigator under `DerivedSources/WooCommerce/` and `DerivedSources/WatchApp/`. Both appear in **red** with an empty **Full Path** in the File Inspector. This is **expected** and **harmless**.

## Why they are red and "not accessible"

Both file references use `sourceTree = DERIVED_FILE_DIR`. `DERIVED_FILE_DIR` is a *per-target, per-configuration* build setting that only has a value while a specific target is actively being built. The project navigator is populated at project-parse time, before any build and with no target/configuration context, so Xcode literally has no way to resolve a single absolute path for the file. The File Inspector still shows **Location: Relative to DERIVED_FILE_DIR**, confirming the declaration is understood — there just isn't one path to display, because the path is different for the `WooCommerce` target vs the `Woo Watch App` target, and different per configuration.

At **build time** Xcode resolves `DERIVED_FILE_DIR` per target, a `Generate Credentials` script build phase on each consumer target writes `ApiCredentials.swift` into that target's own derived sources dir under Derived Data, and the Swift compiler reads it back from that same location. The actual paths look like:

```
~/Library/Developer/Xcode/DerivedData/WooCommerce-<hash>/
  Build/Intermediates.noindex/WooCommerce.build/<config>-<sdk>/
    WooCommerce.build/DerivedSources/ApiCredentials.swift     # WooCommerce target
    Woo Watch App.build/DerivedSources/ApiCredentials.swift   # Woo Watch App target
```

Search a build log for `Generating Credentials` to see the exact path for the current build.

## How to actually view a generated file

1. Build the target at least once.
2. Right-click the red `ApiCredentials.swift` entry in the navigator and pick **Show in Finder** — Xcode will open the per-target derived sources folder for the most recent build of that target.

## The generation pipeline itself

Lives in `WooCommerce/Credentials/` (templates and the secret-substitution script) and `Scripts/build-phases/generate-credentials.sh` (the build phase script).
