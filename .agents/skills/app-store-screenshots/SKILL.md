---
name: app-store-screenshots
description: Capture, review and upload App Store screenshots locally, preserving existing device sets and verifying the selected draft.
user-invocable: true
---

Use Xcode 27.1 or newer with the existing `WooCommerceScreenshots` UI tests and Fastlane. Prefer local generation over the `generate screenshots` CI label. Set `FASTLANE_SKIP_TOOLKIT_UPDATE_CHECK=1` for non-interactive Fastlane commands.

## 1. Confirm scope

Confirm changes to devices, languages, screens or view configurations, retaining prior decisions. Use the Fastfile and `fastlane/screenshots.json` for defaults. Capture-only requests stop after visual review. Upload requires an explicit request; use authorization already given.

The screenshot target sets `shouldShowPOS` to `true` for iPad and `false` for iPhone and Duo, through `SCREENSHOTS_SHOW_POS` and `ProcessConfiguration.shouldShowPOS`. Revisit this setting and the scenes when phone POS screenshots are supported.

## 2. Capture and review

Build once with `bundle exec fastlane build_screenshots`. For ordinary devices, use `take_screenshots languages:en-US devices:"iPhone 17 Pro Max" mode:dark`. This lane recreates selected simulators and shuts down booted ones; coordinate other sessions first.

For Duo, prepare a dedicated simulator. Drag DeviceHub's hinge slider fully open, rotate to landscape and verify the inner display is active. Run the existing test with `xcodebuild test-without-building`; reset-based lanes exclude Duo. Between runs, uninstall only the app; the test reinstalls it with fresh state while preserving Duo's pose.

Set Snapshot's `language.txt`, `locale.txt` and `snapshot-launch_arguments.txt` in `~/Library/Caches/tools.fastlane`. Set simulator appearance and system locale too; restart SpringBoard after locale changes. Create the cache's `screenshots/` folder if absent. Copy its PNGs to `fastlane/screenshots/<locale>/<device>-<N>-<mode>-<title>.png` as required by the composition config.

Compose with `BUNDLE_WITH=screenshots bundle exec fastlane create_promo_screenshots force:true commit:false push:false`. For a subset, set `PROMOSS_CONFIG_FILE` to a temporary config containing only the selected devices and entries. Preserve accepted outputs before replacing or retrying a subset.

Normalize generated promotional PNGs to opaque 8-bit RGB. Validate locale/display recognition with the pinned Fastlane loader, counts/order against the selected config, and dimensions against [Apple's specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications). Inspect every new image for text, appearance, framing and crop. Show a gallery grouped by locale/device, compare with the previous set and report issues before proceeding.

## 3. Prepare the complete upload batch

Use existing Fastlane authentication. If none is usable, ask the user to run `bundle exec fastlane spaceauth` locally. Never print, copy or commit credentials or sessions.

Inventory App Store Connect screenshots by version, locale and display family. Download Watch screenshots and other sets outside capture scope from the actual image assets at native dimensions. Preserve their order, RGB pixels and locale placements. Do not duplicate fallback images into other locales. Derive counts and filenames from this inventory.

Combine these assets with the accepted captures in `fastlane/promo_screenshots`. Save a manifest of locale, display family, order, filename, dimensions and MD5. Compare the complete current inventory with this batch and account for every intended replacement, addition or removal: overwrite deletes all screenshot sets in each uploaded locale.

## 4. Select the draft

Normally take the target version from `config/Version.Public.xcconfig`. Check live and editable versions against the requested target. Select or create the intended draft, which may happen before capture. Never rename a conflicting editable draft to make it fit.

Record the draft's state and release mode, and the live screenshot inventory before upload. For screenshots-only work, keep the draft editable and preserve its release mode.

## 5. Upload within scope

For screenshots-only uploads, use the pinned `Deliver::UploadScreenshots` component with the prepared batch, `overwrite_screenshots: true` and `edit_live: false`. It uses `get_edit_app_store_version`; confirm this resolves to the agreed draft immediately before upload. Keep text metadata, binaries, review submission and release outside this operation.

The existing `update_metadata_on_app_store_connect` lane also writes text metadata. Use that full lane only when metadata updates are authorized. Its `with_screenshots` option controls screenshot replacement.

Local upload does not require an images PR. If the user requests repository updates, use `/pr` for images only through Git LFS and keep infrastructure changes separate.

## 6. Verify and hand off

Wait for every remote image's `asset_delivery_state` to be `COMPLETE`. Compare locale/family counts, order and `source_file_checksum` values with the local MD5 manifest. Confirm draft state/release mode and live screenshot sets are unchanged. Report any missing, pending or failed assets; an upload log alone is not verification.

The release flow can reuse this draft. During later Releases V2 metadata preparation, leave screenshot upload unchecked when retaining the verified batch. Preserve the local batch and verification report for the release handoff.
