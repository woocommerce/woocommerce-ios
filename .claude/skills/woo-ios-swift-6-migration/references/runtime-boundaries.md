# Runtime boundaries

## Switching a target to Swift 6

When a language-mode switch is requested, measure the target and its tests with complete checking. Switch a target only when the module and its test target both have zero warnings. Then build in Swift 6 mode and verify affected callers. Check third-party, Objective-C, delegate, and notification callbacks before you report that the target is ready.

Swift 6 mode is stricter than `SWIFT_STRICT_CONCURRENCY=complete`. A zero-warning measurement does not prove that the switch compiles. The StorageTests switch found errors that the measurement did not report. For example, it rejected a `#file` default passed to a `#filePath` parameter. Expect the same on other test targets. See [the StorageTests switch](https://github.com/woocommerce/woocommerce-ios/pull/17903).

For a package target, set `swiftLanguageMode(.v6)` in `Modules/Package.swift`. For an Xcode target, set `SWIFT_VERSION = 6`. Keep the package tools version at 6.0. The tools version 6.2 change broke explicitly built module dependencies on CI.

A closure can inherit actor isolation that a legacy producer does not obey. Zero warnings do not prove that execution is safe. The `Experiments` switch compiled, but login crashed. ExPlat invoked a completion on a URLSession queue after the closure inherited main-actor isolation. Verify the actual callback path. Add a test that invokes the completion from a supported background context. See [the ExPlat rollback](https://github.com/woocommerce/woocommerce-ios/pull/17845).

If the producer can call from another executor, declare the closure `@Sendable`. Pass only safe values through a continuation. Update actor-owned state after the `await`. `@Sendable` does not select a delivery queue. The notification extension review used this approach while NetworkingCore remained in Swift 5. See [the accepted callback change](https://github.com/woocommerce/woocommerce-ios/pull/17954#discussion_r4153948516).

## Compiler and runtime coverage

The CI compiler can crash where a local compiler does not. Swift 6.3.3 on CI crashed on code that Swift 6.2.3 compiled. A compiler crash prints no source diagnostic. Crashes appear one at a time because the build stops at the first one. Some crashes occur only in optimized archives, so the Debug build and the guard can pass. Validate isolation changes on the `.xcode-version` toolchain with a Debug build, an optimized archive, and the full test run. Read the full archive log, because the formatted CI log can omit the crash. If the compiler crashes while it emits an async Objective-C delegate method, implement the completion-handler form of the method. A `nonisolated` annotation alone did not prevent that crash.

Test new concurrency runtime features on the oldest relevant supported runtime, the CI runtime, and a current OS. Availability and successful compilation do not prove runtime safety. In the WordPressShared migration, `isolated deinit` crashed on iOS 18.4–18.6 but worked on iOS 26. Check this result again for the active toolchain and runtime. It does not prohibit the feature on all versions. See [the deinitializer regression](https://github.com/woocommerce/woocommerce-ios/pull/17916).

For shared source files, identify every target that compiles them. Check each conditional compilation branch. The Watch migration changed isolation in files also used by widgets and app tests. Build these targets with their own platform and language settings. Explain any isolation that differs by target. See [the shared-source review](https://github.com/woocommerce/woocommerce-ios/pull/17950#discussion_r4118437875).

## Callback-to-async changes

Keep synchronous paths, immediate return values, retry counts, and capture lifetime unchanged. A new task can start later than the original code. Prevent duplicate requests at the operation entry point when necessary. Changing a strong capture to weak can prevent completion UI from appearing. An async instance method can retain its owner until the call ends. The open Settings PRs show these risks. Check them in the current code before you use the same approach. See [the Settings changes](https://github.com/woocommerce/woocommerce-ios/pull/18010) and [capture lifetime](https://github.com/woocommerce/woocommerce-ios/pull/18016).

Check publisher delivery order when you change state storage. Replacing `@Published` with a subject can change the value subscribers read during a callback. Check the subscribers and test the delivery order. See [the connectivity observer migration](https://github.com/woocommerce/woocommerce-ios/pull/17879).

Cancellation handlers can execute outside the owner's actor. Keep cancellation entry points callable from that context. Use safe synchronous state access when required. Prevent old attempts from affecting new work. Keep this cancellation behavior when you move the owner to the main actor. See [the preflight cancellation contract](https://github.com/woocommerce/woocommerce-ios/pull/17994).
