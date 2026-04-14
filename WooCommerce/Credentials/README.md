# Credentials

This folder holds the inputs used to generate `ApiCredentials.swift`, the Swift file that exposes the app's API keys and secrets to the rest of the codebase.

## Files

- `ApiCredentials.tpl` — the template that the generation script renders into a real `ApiCredentials.swift` by substituting placeholders with values from the secrets file.
- `Templates/ApiCredentials-Template.swift` — a placeholder file with empty values, used when the secrets file is missing (e.g. external contributors).
- `replace_secrets.rb` — the substitution script used by the build phase.

The secrets file itself lives outside the repo at `~/.configure/woocommerce-ios/secrets/woo_app_credentials.json`. Internal contributors can populate it with `bundle exec fastlane run configure_apply`.

## Where the generated file lives

`ApiCredentials.swift` is **not** in the repo and is **not** in the source tree on disk. It is generated at build time into each consumer target's per-target Derived Sources folder under Derived Data:

```
~/Library/Developer/Xcode/DerivedData/WooCommerce-<hash>/
  Build/Intermediates.noindex/WooCommerce.build/<config>-<sdk>/
    WooCommerce.build/DerivedSources/ApiCredentials.swift     # for the WooCommerce target
    Woo Watch App.build/DerivedSources/ApiCredentials.swift   # for the Woo Watch App target
```

Each target that compiles `ApiCredentials.swift` has its own `Generate Credentials` script build phase (defined in the Xcode project, invoking `Scripts/build-phases/generate-credentials.sh`). The phase runs before Compile Sources and writes the file into that target's own `$(DERIVED_FILE_DIR)`. The Swift compiler then picks it up from there.

## Why `ApiCredentials.swift` shows as red in Xcode's project navigator

Both `ApiCredentials.swift` references in the project navigator (under `DerivedSources / WooCommerce` and `DerivedSources / WatchApp`) appear in red, with an empty "Full Path" in the File Inspector. This is **expected** and **harmless**.

The file references use `sourceTree = DERIVED_FILE_DIR`, which is a per-target, per-configuration build setting. It only has a value while a specific target is actively being built. The project navigator runs at project-parse time, *before* any build, with no target/configuration context — so Xcode literally cannot fill in a single absolute path for the file.

The File Inspector confirms the directive is understood: it shows **Location: Relative to DERIVED_FILE_DIR**. There just isn't a single absolute path to display, because the path is different for the WooCommerce target vs the Woo Watch App target, and different per build configuration.

At build time, Xcode resolves `DERIVED_FILE_DIR` per target, the script phase writes the file into that target's derived sources dir, and the compile step reads it from the same location. Build logs confirm this — search for `Generating Credentials` in the build output and you'll see paths under `…/WooCommerce.build/<config>-<sdk>/<target>.build/DerivedSources/ApiCredentials.swift`.

## Trying to view the generated file

If you want to see what the generated file actually contains for a given target:

1. Build the target at least once.
2. In the Project Navigator, right-click the red `ApiCredentials.swift` reference and pick **Show in Finder**. Xcode will open the per-target derived sources folder for the most recent build of that target.
3. Or, from the terminal, look under `~/Library/Developer/Xcode/DerivedData/WooCommerce-*/Build/Intermediates.noindex/WooCommerce.build/`.
