# Recurring migration patterns

Check each pattern against the active compiler, SDK, deployment target, and callers. Different toolchains can change API isolation and feature availability.

## Timers and delayed work

For a repeating UI timer, keep its start and stop behavior unchanged. Check where the timer is scheduled and where its callback runs. If main-actor code schedules it on the main run loop, document that guarantee. Then consider `MainActor.assumeIsolated` around its `@Sendable` callback body. An extra `Task { @MainActor in ... }` changes execution order. Queued work can execute after the timer stops.

For a one-shot timeout, store the task and inject the sleep function. This lets tests control cancellation:

```swift
// On a @MainActor owner; sleep is an injected @Sendable async closure.
func startTimer() {
    timeoutTask?.cancel()
    timeoutTask = Task { [weak self, sleep] in
        do { try await sleep(.seconds(10)) } catch { return }
        guard !Task.isCancelled else { return }
        self?.onTimeout()
    }
}
```

Use a controlled sleep function to test timeout, cancellation after sleep returns, and restart. Await task completion instead of waiting a fixed time. For repeating async work, consider `AsyncTimerSequence` if the target already links swift-async-algorithms.

## Environment and preference defaults

A shared `static let` of a non-`Sendable` type can introduce global mutable state. For a default without state, consider a computed `static var` that returns a new value. An immutable value type is another option. Use `let` for static layout values that are constant.

Before you replace a default that reads `UIScreen.main.bounds`, check every reader and presentation path. A zero or estimated size can change sheets, full-screen covers, or root views that use the default. Prefer the measured container size. Pass it to the presented view. Identify defaults used only by previews. Verify the affected layouts.

## Deinitialization

Check whether the active compiler and deployment target support `isolated deinit`. A deinitializer without isolation cannot safely access actor-owned, non-`Sendable` state. See [SE-0371](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0371-isolated-synchronous-deinit.md).

- For a token written once during initialization and read only during cleanup, consider a temporary unsafe annotation on its storage. First, check aliases and token removal behavior. Document the safety evidence.
- To compare and clear shared state synchronously, consider `Synchronization.Mutex` where supported. An async cleanup task changes when cleanup takes effect.
- For a UI change with only `Sendable` inputs, consider a main-actor task if delayed execution is acceptable. Test the execution order when a new instance or state replaces the old one.
- If an observer only needs to be released, stored-property destruction can provide the required cleanup. Confirm cancellation behavior before you remove explicit cleanup calls.

## Isolation placement and closures

Isolate individual protocol requirements when only those operations need the main actor. An annotation on the whole protocol can also change conformer initialization. It can require changes in unrelated callers.

If all state belongs to the main actor, declare isolation explicitly on the owner type. Do not rely only on inferred isolation from a conformance. Some helpers inherit UIKit isolation but only read type metadata. Consider `nonisolated` on these helpers before you change their callers. See [explicit owner isolation](https://github.com/woocommerce/woocommerce-ios/pull/17949#discussion_r4103103821) and [reuse identifiers](https://github.com/woocommerce/woocommerce-ios/pull/17867#discussion_r4025100655).

A main-actor type that conforms to a nonisolated protocol gets a warning on the conformance itself. To isolate one conformer without changing the shared protocol or its other conformers, use an isolated conformance, such as `extension WordPressMediaLibraryPickerDataSource: @MainActor WPMediaCollectionDataSource`. Objective-C protocol requirements are nonisolated. An isolated conformance is correct only if the framework calls the delegate on the main thread, as `OrderEmailComposer` does with `MFMailComposeViewControllerDelegate`. If the delegate can be called from another queue, keep its methods nonisolated and move the work to the main actor inside them. Types from the fenced `WordPressAuthenticator` target need wrappers, not new conformances.

If an actor-isolated default argument fails in a supported build configuration, accept `nil` as the default. Construct the dependency inside the isolated function body. Verify strict and default build settings. Compiler versions can evaluate default arguments differently.

Do not use a `nonisolated init` on a global-actor class to avoid changing callers. Each assignment of a non-`Sendable` stored property in that initializer produces a warning. It stays quiet only when every stored property is `Sendable`. See [the order details data source](https://github.com/woocommerce/woocommerce-ios/pull/17981), where it added 14 warnings.

An implementation without state can provide a `nonisolated` async witness for an isolated UI-facing requirement. Use this option only if its dependencies control concurrent access. Check direct calls to the concrete implementation separately. Protocol isolation alone does not make the implementation `Sendable`.

If a `@Sendable` closure captures a generic SwiftUI view, capture only the required `Sendable` dependencies when possible. For Combine callbacks, check the scheduler and actor isolation.

Check each UIKit lifecycle or Objective-C callback separately. Use `MainActor.assumeIsolated` only if the framework guarantees main-actor delivery and the body accesses UI state. Test the callback path. A documented main-queue notification callback can meet these conditions. For app-owned protocols, declare isolation that the compiler checks. An `assumeIsolated` wrapper reached from a nonisolated requirement can add a `sending` warning for each captured value. In one uploader, the count went from 7 to 14.

## Test fixtures and mocks

Put `@MainActor` on XCTest methods, not on the `XCTestCase` subclass. The class-level annotation conflicts with the nonisolated `setUp()` and `tearDown()` overrides. Use `override func setUp() async throws` if setup must run on the main actor. The same conflict occurs with other nonisolated superclasses, such as `ScreenObject`. When the type under test is an actor, do not make the suite `@MainActor`. Make its mocks actors instead. See [catalog test isolation](https://github.com/woocommerce/woocommerce-ios/pull/18006).

Keep tests that run work in parallel on purpose nonisolated. Examples are tests that use `concurrentPerform`, `async let`, or `TaskGroup`. Main-actor isolation stops the parallel execution that they test. Protect their shared state with a lock or `Mutex`. If a test depends on main-actor ordering, make that dependency explicit.

Construct UI fixtures inside a main-actor test or factory. Nonisolated XCTest setup is not suitable for their construction. Use computed fixtures to create separate mutable values for each test. Keep immutable `Sendable` fixtures shared when their identity or generated timestamp must remain constant. A computed property can return different test data on each read. See [the fixture review](https://github.com/woocommerce/woocommerce-ios/pull/17867#discussion_r4025136932).

When a protocol gains `Sendable`, check production and test conformers. Callback properties can need `@Sendable`. Build the code that creates these callbacks to check captured test state. Keep cleanup helpers compatible with their deinitializer isolation.

For mutable mocks, prefer an actor when the protocol supports async access. If synchronous requirements need a lock, protect the complete state operation. Separate locked getters and setters do not make a dictionary subscript update atomic. Return snapshots for reads. Use methods that change state under one lock. Copy callbacks while the lock is held. Release the lock before you invoke them. See [the addressed mock-state review](https://github.com/woocommerce/woocommerce-ios/pull/17974#discussion_r4152621462).

To check the intermediate state of a main-actor `@Observable` property, prefer the mock callback hook from `Modules/Tests/CLAUDE.md`. Check the state inside the hook, and check the final state after the call. Also check that the mock was called, because a hook that does not run checks nothing. Do not use `withObservationTracking` with `MainActor.assumeIsolated` or with a `@Sendable` helper that captures mutable state. An observation recorder that reads the value in a `Task { @MainActor in }` needs a suspension between changes. It misses states if the mock is main-actor isolated or if `NonisolatedNonsendingByDefault` is on. The hook runs inside the call, so it does not depend on the executor. See `PointOfSaleOrderControllerTests` and [the review](https://github.com/woocommerce/woocommerce-ios/pull/18033).

When you replace test coordination, keep operations overlapping. Check duplicate requests, progress, and cancellation while the first operation is still running. Follow the callback-hook guidance in `Modules/Tests/CLAUDE.md`. Paired readiness and suspension continuations can race. A main-actor annotation alone does not prove that a concurrent mock is safe. See [catalog test coverage](https://github.com/woocommerce/woocommerce-ios/pull/18006) and [concurrent mock requests](https://github.com/woocommerce/woocommerce-ios/pull/17974).

## Payloads at callback boundaries

Inside the callback, extract the required `Sendable` IDs, values, or validated `Data`. Do this before you pass values to another actor or create child tasks. Keep non-`Sendable` notification models and type-erased containers in their original isolation context. Use the existing `RequestParameterValue` type for network parameters. Do not assume that `[String: Any]` is safe to send. See [notification loading](https://github.com/woocommerce/woocommerce-ios/pull/17954), [Watch payload snapshots](https://github.com/woocommerce/woocommerce-ios/pull/17950), and [typed request parameters](https://github.com/woocommerce/woocommerce-ios/pull/17370).
