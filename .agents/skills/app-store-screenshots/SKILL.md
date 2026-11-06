---
name: app-store-screenshots
description: Generate App Store screenshots locally, compare them with the previous set, and prepare an image PR after review.
user-invocable: true
---

Use the existing `WooCommerceScreenshots` UI tests and Fastlane lanes. Generate locally rather than adding the `generate screenshots` GitHub label.

## 1. Confirm changes

Ask whether devices, languages, screens or view configurations need to change. Keep decisions already made. Use the current Fastfile and `fastlane/screenshots.json` for everything else.

## 2. Capture locally

Build once with `bundle exec fastlane build_screenshots`. Run `take_screenshots` for each agreed appearance, for example:

```sh
bundle exec fastlane take_screenshots languages:en-US devices:"iPhone Duo" mode:dark
```

The lane resets its selected simulators. Raw images go to `fastlane/screenshots/<locale>`. Review a representative set before expanding a changed configuration. Keep accepted captures when retrying a subset.

## 3. Compose and compare

For Duo, accept Apple's Design Resources license and prepare its official inner-open-landscape PNG with `BUNDLE_WITH=screenshots bundle exec ruby fastlane/helpers/prepare_duo_screenshot_assets.rb /path/to/official.png`.

Run `BUNDLE_WITH=screenshots bundle exec fastlane create_promo_screenshots force:true commit:false push:false`. Inspect every new image in `fastlane/promo_screenshots` and compare with the previous set. Check text, light/dark mode, framing and crop. Preserve accepted images before a targeted recapture.

## 4. Show the results

Create a local gallery with previous and new images side by side, grouped by locale and device. Share its URL and report the scope, checks and issues. Ask the user to review the set.

## 5. Prepare the image PR

After acceptance, use `/pr` for an images-only PR from the reviewed promotional files through Git LFS. Keep infrastructure changes separate. Preserve the complete release set, including Watch images. During an authorized release, select screenshots in the Releases V2 metadata task and check App Store Connect after processing. Merge and upload need separate authorization.
