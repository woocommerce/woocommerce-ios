# App Store screenshots

## Generate and review

1. When changing Xcode or devices, check `simctl list runtimes --json` and each runtime's `supportedDeviceTypes`. An installed runtime may support Duo but exclude ordinary iPhones and iPads.
2. Add `generate screenshots` to a same-repository PR. The [workflow](../../.github/workflows/screenshots.yml) captures the configured locales and modes, creates promotional images, and opens an asset PR against the source PR.
3. Monitor every job through completion. For failures, save successful artifacts and read the failing log and result bundle before retrying. Record the revision, runtime, locale and mode of saved captures. Reuse them only if the app UI and capture settings are unchanged.
4. Inspect every locale and device set. Check the scene, translated UI, caption fit, orientation and cropping. Notification images must show the mocked order notification. A test can pass while capturing the previous screen.
5. Check every expected file's dimensions and absence of alpha or transparency. Use the locked image library for encoding checks. Report generation complete only when file checks and visual review cover the whole set. Leave the asset PR unmerged until merging is authorized.

## Release handoff

The asset PR commits promotional images to `fastlane/promo_screenshots` through Git LFS. Raw captures remain CI artifacts. If the folder is absent, check whether the asset PR was merged. A successful generation job does not put images on the release branch.

For an authorized upload, first include the reviewed images in the intended release branch. Select "Yes" for screenshots in the Releases V2 metadata task. Its `WITH_SCREENSHOTS` option uploads files from that branch's promotional folder.

The overwrite upload replaces every screenshot family in each included locale. Preserve the complete replacement set, including manually maintained Watch images when present. Uploading a Duo-only folder would remove that locale's existing iPhone and iPad images.

Recheck App Store Connect after processing. Past uploads initially appeared successful, then showed errors. Check the public listing after release, when the changes become visible.

## Configuration

- [Fastlane lanes](../../fastlane/Fastfile) define locales, devices, runtimes and uploads.
- [Composition configuration](../../fastlane/screenshots.json) defines scenes and captions. Run its [existing checks](../../fastlane/helpers/promo_screenshots_config_test.rb) after changes.
- Recheck [Apple's requirements](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications) when changing assets. Confirm the locked Fastlane version recognizes the selected Duo dimensions.
