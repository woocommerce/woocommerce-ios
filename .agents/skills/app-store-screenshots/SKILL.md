---
name: app-store-screenshots
description: Generate App Store screenshots locally, compare them with the previous set, and prepare an image PR after review.
user-invocable: true
---

Use Xcode 27.1 or newer with the existing `WooCommerceScreenshots` UI tests and Fastlane lanes. Generate locally rather than adding the `generate screenshots` GitHub label.

## 1. Confirm changes

Ask whether devices, languages, screens or view configurations need to change. Keep decisions already made. Use the current Fastfile and `fastlane/screenshots.json` for everything else.

The screenshot target sets `shouldShowPOS` to `true` for iPad and `false` for iPhone and Duo. It passes this through `SCREENSHOTS_SHOW_POS` to `ProcessConfiguration.shouldShowPOS`. Update this setting and the captured scenes when phone POS screenshots are supported.

## 2. Capture locally

Build once with `bundle exec fastlane build_screenshots`. Use the existing screenshot tests for the agreed devices, locales and appearances.

For Duo, prepare a dedicated simulator, open it fully and rotate it to landscape with the available simulator controls. Confirm that the app is visible on the inner display. Run the existing `WooCommerceScreenshots` test with `xcodebuild test-without-building` on that simulator. The reset-based `take_screenshots` and `screenshots` lanes capture ordinary devices only.

For each direct Duo run, set Snapshot's `language.txt`, `locale.txt` and `snapshot-launch_arguments.txt` in `~/Library/Caches/tools.fastlane`, and set the simulator appearance before capture. Set the simulator's system language and locale too, then restart SpringBoard so Notification Center uses that locale. Create `~/Library/Caches/tools.fastlane/screenshots/` if it is absent. Snapshot saves `<simulator-name>-<N>-<light|dark>-<title>.png` under that cache's `screenshots/` folder. Copy each run's files to `fastlane/screenshots/<locale>/`, using the `iPhone Duo-` device prefix expected by `fastlane/screenshots.json`. Confirm inner-display landscape dimensions before composition.

For ordinary devices, use `take_screenshots`, for example:

```sh
bundle exec fastlane take_screenshots languages:en-US devices:"iPhone 17 Pro Max" mode:dark
```

Fastlane deletes selected simulators and shuts down other booted simulators, so check for other sessions first. Review a representative set before expanding a changed configuration. Keep accepted captures when retrying a subset.

## 3. Compose and compare

Run `BUNDLE_WITH=screenshots bundle exec fastlane create_promo_screenshots force:true commit:false push:false`. Inspect every new image in `fastlane/promo_screenshots` and compare with the previous set. Check text, light/dark mode, framing and crop. Preserve accepted images before a targeted recapture.

## 4. Show the results

Create a local gallery with previous and new images side by side, grouped by locale and device. Share its URL and report the scope, checks and issues. Ask the user to review the set.

## 5. Prepare the image PR

After acceptance, use `/pr` for an images-only PR from the reviewed promotional files through Git LFS. Keep infrastructure changes separate. Preserve the complete release set, including Watch images. During an authorized release, select screenshots in the Releases V2 metadata task and check App Store Connect after processing. Merge and upload need separate authorization.
