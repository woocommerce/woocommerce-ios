---
name: woo-ios-swift-6-migration
description: Diagnose and fix Swift strict-concurrency warnings in WooCommerce iOS. Use for Swift 6 migration, actor-isolation changes, and Sendable diagnostics in this repository.
user-invocable: true
allowed-tools: "Bash, Read, Write, Edit, Grep, Glob"
---

# WooCommerce iOS Swift 6 migration

Make small changes in the requested scope. Verify each change. For diagnosis or review requests, read the code without changing it. Change the Swift language mode or target scope only when requested.

## Check the build settings and measure warnings

Read the repository instructions and the documentation for the affected module. Check these settings before you analyze warnings:

- Xcode and Swift versions.
- Swift language mode.
- Strict-concurrency level.
- Default actor isolation.
- Enabled upcoming features.

Identify the affected targets and dependencies.

The strict-concurrency level has three sources. In order of precedence, they are the `xcodebuild` command line, the target build settings, and the project build settings. Swift package targets ignore the Xcode build settings. They use only the command-line value or `swiftSettings` in `Modules/Package.swift`. Pass `SWIFT_STRICT_CONCURRENCY=complete` on the command line, or package targets are not measured. The command-line value also overrides target-level fences. The `WordPressAuthenticator` target keeps a trailing `-strict-concurrency=minimal` in `OTHER_SWIFT_FLAGS` for this reason. Do not change `WordPressAuthenticator`. It is fenced on purpose, and Swift 6.3.3 crashes while formatting one of its diagnostics under complete checking.

Do not set `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor` on a whole target. On the pinned toolchain, it caused compiler crashes, an optimizer crash in Release-Alpha archives ([swiftlang/swift#88173](https://github.com/swiftlang/swift/issues/88173)), and XCTest crashes in `swift_task_deinitOnExecutorMainActorBackDeploy`. Its warning counts are not comparable with normal measurements. Use explicit `@MainActor`, `nonisolated`, and `Sendable` declarations instead.

Use the repository build, test, and simulator workflows. To measure workspace warnings, use the existing script with a new DerivedData directory:

```bash
Scripts/StrictConcurrency/count-warnings.sh /tmp/<task>-before.json
```

Read the script before you change its build settings. For a smaller scope, select the affected scheme and an available simulator. Use `build-for-testing` with `SWIFT_STRICT_CONCURRENCY=complete`. Use a separate DerivedData directory for each build configuration. Check disk space before large builds.

Save the build log. Record warnings by target, file path relative to the repository, and diagnostic text. Use the same build scope and settings before and after the change. Remove repeated compiler output with the same method in both logs. Compare warnings without line and column numbers. Keep the file path and number of occurrences.

Use a clean build for each measurement. If you use an incremental build, confirm that every measured file compiled. An incremental log can omit unchanged files. Use a partial build result only if every file in the measured scope compiled. Do not use a partial build to measure the workspace or update its baseline.

The CI toolchain in `.xcode-version` is authoritative. A different local Xcode produces a different warning set. For example, local Xcode 26.2 measured 10,992 warnings where CI's Xcode 26.6 measured 11,158. Some Xcode versions cannot compile trunk at all. Label local counts as local.

Record the base commit, head commit, and toolchain used for measurement. For stacked PRs, identify changes from the parent PR separately. The baseline guard is advisory. It can report warnings already on trunk. Its parser counts all Swift warnings in the repository. Check the base result and original diagnostics before you attribute new warnings to the change. Label estimates separately from measured counts. Check incomplete or repeated log lines before you change the baseline. See [the guard discussion](https://github.com/woocommerce/woocommerce-ios/pull/17816#discussion_r3965177979) and [inherited regressions](https://github.com/woocommerce/woocommerce-ios/pull/17929).

## Select and apply isolation

Start at the warning. Check the owner, protocol, conformers, direct callers, and dependencies. Before you edit code, identify which actor owns each value or operation:

| Ownership | Preferred approach |
|---|---|
| UI, navigation, or main-thread-owned state | `@MainActor` on the owner or relevant requirement |
| Shared mutable state | An actor or an existing owner that serializes access |
| Values passed between actors | `Sendable`, with safe stored values and access |
| Legacy dependency outside the scope | A limited compatibility annotation with safety evidence |

Apply isolation to the required declarations and callers. Stop where the existing code has isolation that the compiler checks. Keep construction order, service lifetime, cancellation, retry, cached state, and UI presentation unchanged. Build after each isolation change. Check for new warnings in callers.

Isolation violations are errors, not warnings, at every strictness level. A synchronous call from nonisolated code to a `@MainActor` member of the same module fails under `minimal` and Swift 5 too. Only `Sendable` diagnostics are warnings at that level. Change every nonisolated caller in the same commit, including tests. Emit-module stops at the first error, so each hop of callers costs one build. Change the obvious callers together before you build. See [the product image handler](https://github.com/woocommerce/woocommerce-ios/pull/17874).

When a slice must change a shared contract, such as a widely used protocol or a closure type, change it in place. Do not add a parallel API to keep the baseline guard flat. Swift cannot overload on `@Sendable` alone. Do not deprecate the old API either, because the guard counts deprecation warnings too. Raise the affected baseline entries in the same PR and explain why. Later slices lower them.

Some diagnostics show an architectural boundary, not a missing annotation. An example is "non-Sendable parameter type cannot be sent from caller of protocol requirement into main actor-isolated implementation". It needs a decision about the isolation contract of that boundary. Stop and report the decision to the user. Do not treat it as a mechanical fix.

Read the reference that applies to the change:

- [Recurring patterns](references/patterns.md): timers, environment and preference defaults, deinitialization, isolated conformances, initializers, default arguments, framework callbacks, test isolation, and test fixtures.
- [Session service boundaries](references/session-services.md): POS eligibility, session construction, publishers, protocol witnesses, legacy async remotes, and Action completions.
- [Runtime boundaries](references/runtime-boundaries.md): language-mode switches, mixed Swift 5/6 callbacks, compiler crashes, supported OS runtimes, shared target sources, and callback-to-async changes.

For general Swift concurrency guidance, use the `swift-concurrency` skill if available. Otherwise, read the public [Swift Concurrency skill](https://github.com/AvdLee/Swift-Concurrency-Agent-Skill/blob/main/skills/swift-concurrency/SKILL.md). Read only the reference needed for the diagnostic. Resolve its relative links from the upstream skill directory. Check guidance against the active toolchain. Keep this repository's scope and verification rules.

If complete isolation needs a larger migration, use a limited adapter when possible. The compiler must check its isolation, and it must keep the same behavior. Describe the remaining work and when to remove the adapter. Expand `ServiceLocator` or `StoresManager` only when the required ownership change justifies it.

## Check compatibility annotations

For `@preconcurrency`, `@unchecked Sendable`, and `nonisolated(unsafe)`, provide evidence that access is safe. Prefer an annotation on a declaration or conformance. Use `@preconcurrency import` only for third-party modules, never for this repository's own modules. Use it only if the dependency has no usable concurrency contract and a more specific annotation is insufficient. Do not add `@unchecked Sendable` only to silence a diagnostic. Fix the type, or isolate it.

For an unchecked reference or conformance, check every alias and access path. Show how each path protects mutable state. A `let` reference does not make the referenced object thread-safe. Add a nearby comment. State which concurrency contract is missing and when to remove the annotation. Describe the remaining risk in the PR.

`@preconcurrency` on a conformance does not move execution to an actor. A synchronous protocol call can compile and then fail a runtime isolation check. Confirm which actor executes each entry point. Test the actual protocol or callback path. Build the callers again. See [SE-0423](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0423-dynamic-actor-isolation.md).

Use `MainActor.assumeIsolated` only where a documented contract guarantees main-actor execution. It checks the current executor. It does not move work to the main actor. For app-owned construction and calls, use isolation declarations that the compiler checks.

## Verify the complete change

The target result is zero warnings in the requested scope. There must be no new warning occurrences in files built under comparable conditions. A new file has no baseline entry, so it must have zero warnings. Compare diagnostic text as well as counts. A lower total can hide new warnings in callers. An unchanged file count can hide a different unsafe operation. If dependencies prevent completion, report the remaining warnings and proposed work. Explain each baseline increase separately. Warnings removed elsewhere do not justify an increase.

1. Repeat the strict build with the baseline settings. Compare warnings in the changed files and direct callers.
2. Run the relevant tests with default build settings too. Changed strict-build settings can change which isolation warnings appear.
3. If changes cross module boundaries, run the affected module tests. Run the repository lint workflow.
4. For changes to scheduling, navigation, lifecycle, or visible timing, verify the affected user flow. For layout or presentation changes, use [UI regression evidence](references/ui-regression-proof.md).
5. For a new race or cancellation test, temporarily remove the code that prevents the failure. Confirm that the test fails. Restore the code before you continue.
6. Review all changes against the requested base. Include earlier branch commits and current edits. Search all these changes for compatibility annotations and `assumeIsolated` before you report that none were added.

Report failed checks as failed. Report blocked checks as inconclusive. A passing test with a smaller scope does not change these results.

If a baseline update is requested, use `Scripts/StrictConcurrency/update-baseline.sh` with the guard's CI artifact only. Local measurements use a different toolchain. The script treats missing files as zero warnings. Input from a smaller scope would remove unrelated baseline entries. Use `compare-baseline.sh` to check the result. Do not use partial measurements with that script to claim workspace improvements.

- After a rebase conflict in `baseline.json`, take one side of the file. Then run `update-baseline.sh` with a new artifact. Do not merge the counts by hand.
- `update-baseline.sh` only lowers counts. To reset a baseline that has inherited increases from trunk, copy the trunk artifact over `baseline.json`. Then run `compare-baseline.sh` and expect equal totals. Use an artifact from trunk or from the reset PR's own run, never from another PR. See [the first reset](https://github.com/woocommerce/woocommerce-ios/pull/17902).
- A commit that only triggers CI must change more than `.md`, `.txt`, or `docs/` files. `should-skip-job.sh` skips the guard for those changes.

## Report evidence

Report the root cause first. Give warning counts before and after for each file in scope. Identify new warnings. Include passed, failed, and inconclusive checks. List compatibility annotations and when to remove them.

Explain changes outside the named feature that were necessary after isolation changed. Verify their user flows too. Reviewers can miss these changes, as shown in [the onboarding review](https://github.com/woocommerce/woocommerce-ios/pull/17880#discussion_r4035767670).

Include generated logs, screenshots, and local notes in the change only when requested. Update baselines, issue state, PRs, or remote branches only when the user authorizes that action.
