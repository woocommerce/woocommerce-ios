# App Store screenshots

Generation, image review, merging, and live App Store Connect upload are separate actions. Follow the user's authorized scope for each.

## Generate and review

1. Inspect `fastlane/Fastfile` for locales, devices and runtime mapping, and `fastlane/screenshots.json` for promotional scenes and captions. Runtime compatibility differs by device even within one Xcode installation; check `simctl list runtimes --json` and `supportedDeviceTypes` before a full run.
2. Add `generate screenshots` to a same-repository PR. The workflow builds mocked screenshot tests, captures the locale/mode matrix, composes images, and opens a separate generated-assets PR targeting the source PR. Monitor every capture and processing job through completion.
3. Preserve successful artifacts before retrying failures. Read the first failure's full log and result bundle; fix its cause before rerunning. Reuse captures only when their app revision, runtime, locale and mode are known and suitable for the intended output.
4. Review every locale and device set. Check scene content, translated UI and captions, clipping, orientation and alignment. Confirm notification screenshots contain the actual mocked notification; a passing test or correctly sized PNG can still contain the preceding screen.
5. Require complete configured output sets and PNGs without alpha channels or transparency. Run existing composition configuration checks and decode generated images with the locked rendering library; a mocked API or substitute renderer is insufficient.
6. Finish generation/review only after the generated images pass both file checks and visual review. Keep the generated-assets PR unmerged until merging is authorized.

## Release handoff

Reviewed promotional files belong in `fastlane/promo_screenshots`, tracked by Git LFS. Raw screenshots are ignored by Git and retained as CI artifacts. A generated-assets PR or successful workflow does not establish that images were merged; check the branch and PR history when the folder is absent.

Include the reviewed assets in the intended release branch before choosing **Yes** for screenshots in the Releases V2 metadata task. Its `WITH_SCREENSHOTS` option controls the upload; ordinary metadata updates keep it off. The lane reads the committed promotional folder, not arbitrary past GitHub artifacts.

The overwrite uploader replaces all screenshot families in each included locale. Inventory and preserve the complete intended family sets before an authorized upload, including separately maintained Watch assets when present. A Duo-only folder is not a safe replacement for an existing multi-family locale.

Check App Store Connect again after processing; past uploads initially appeared successful and later showed errors. Check the public listing after release, since some metadata changes are not visible earlier.

## Sources of truth

- [Generation and processing workflow](../../.github/workflows/screenshots.yml)
- [Fastlane lanes](../../fastlane/Fastfile), [composition configuration](../../fastlane/screenshots.json), and [existing configuration checks](../../fastlane/helpers/promo_screenshots_config_test.rb)
- [Apple screenshot requirements](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications): recheck dimensions, formats and display-family requirements when changing assets. Verify the locked Fastlane version recognizes the selected Duo size.
