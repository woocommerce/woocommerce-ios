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

If all state belongs to the main actor, declare isolation explicitly on the owner type. A conformance in the primary type declaration to a main-actor-isolated protocol also infers main-actor isolation for the owner. Rely on that inference only when the protocol deliberately defines the isolation of every conformer, and keep the conformance in the primary declaration: moving it to an extension removes the owner's inferred isolation. Some helpers inherit UIKit isolation but only read type metadata. Consider `nonisolated` on these helpers before you change their callers. See [explicit owner isolation](https://github.com/woocommerce/woocommerce-ios/pull/17949#discussion_r4103103821) and [reuse identifiers](https://github.com/woocommerce/woocommerce-ios/pull/17867#discussion_r4025100655).

When a UI wrapper stores callbacks that are supplied from a main-actor owner, preserve that contract on the closure type itself with `@MainActor @Sendable`. Pass a contextually typed closure literal that calls the actor-isolated method; a direct method reference is still a non-`Sendable` function value and warns during conversion. Explicit isolation on the owner alone does not prevent the conversion from losing its global actor or producing a region-isolation warning during actor-isolated initialization. Confirm that every invocation originates from a main-actor framework callback before strengthening the closure contract.

A main-actor type that conforms to a nonisolated protocol gets a warning on the conformance itself. To isolate one conformer without changing the shared protocol or its other conformers, use an isolated conformance, such as `extension WordPressMediaLibraryPickerDataSource: @MainActor WPMediaCollectionDataSource`. Objective-C protocol requirements are nonisolated. An isolated conformance is correct only if the framework calls the delegate on the main thread, as `OrderEmailComposer` does with `MFMailComposeViewControllerDelegate`. If the delegate can be called from another queue, keep its methods nonisolated and move the work to the main actor inside them. Types from the fenced `WordPressAuthenticator` target need wrappers, not new conformances.

An isolated conformance does not make its witness declarations actor-isolated for direct calls. Add explicit isolation to each witness that accesses actor-owned state or APIs; callers using the concrete type are checked against the witness declaration rather than the conformance boundary.

If an actor-isolated default argument fails in a supported build configuration, accept `nil` as the default. Construct the dependency inside the isolated function body. Verify strict and default build settings. Compiler versions can evaluate default arguments differently.

Do not use a `nonisolated init` on a global-actor class to avoid changing callers. Each assignment of a non-`Sendable` stored property in that initializer produces a warning. It stays quiet only when every stored property is `Sendable`. See [the order details data source](https://github.com/woocommerce/woocommerce-ios/pull/17981), where it added 14 warnings.

An implementation without state can provide a `nonisolated` async witness for an isolated UI-facing requirement. Use this option only if its dependencies control concurrent access. Check direct calls to the concrete implementation separately. Protocol isolation alone does not make the implementation `Sendable`.

To make UI button actions crossable, type them `@MainActor @Sendable () -> Void`. A closure literal written in a main-actor context can then capture non-`Sendable` values, such as a completion handler or a provider existential, without a warning. A plain `() -> Void` local or parameter that is passed on still warns, and so does a closure returned from `Optional.map` unless its return type is written out (`map { x -> @MainActor @Sendable () -> Void in ... }`). Type the local, or wrap the parameter in a literal (`{ onCompleted() }`). Code that unpacks these actions into a plain `() -> Void` must itself be main actor; nonisolated code cannot call them at all. When a protocol becomes `@MainActor`, its conformers' explicit initializers become main actor, but implicit ones stay nonisolated. See [the card present payment payloads](https://github.com/woocommerce/woocommerce-ios/pull/17980).

If a `@Sendable` closure captures a generic SwiftUI view, capture only the required `Sendable` dependencies when possible. For Combine callbacks, check the scheduler and actor isolation.

Do not use `DispatchQueue.main.sync` from an initializer that can run inside a lazy static service initializer. A background caller can hold the static initialization lock while waiting for main, as the main thread waits for the same static value. For a main-actor-derived value, initialize lock-protected state with a safe fallback and queue an asynchronous main-actor refresh. Add a regression test that constructs the service off-main while the main thread waits synchronously, so a blocking hop reliably times out.

Check each UIKit lifecycle or Objective-C callback separately. Use `MainActor.assumeIsolated` only if the framework guarantees main-actor delivery and the body accesses UI state. Test the callback path. A documented main-queue notification callback can meet these conditions. For app-owned protocols, declare isolation that the compiler checks. An `assumeIsolated` wrapper reached from a nonisolated requirement can add a `sending` warning for each captured value. In one uploader, the count went from 7 to 14.

When a remote strengthens a completion to `@MainActor @Sendable`, propagate `@Sendable` through action cases and forwarding helpers. A declaration-level `@preconcurrency` annotation does not suppress the complete-checking warning when a Swift 5 caller forwards a non-`Sendable` closure. Keep the main-actor annotation at the delivery boundary; upstream layers that only forward the closure do not need to become main-actor isolated.

## Test fixtures and mocks

Put `@MainActor` on XCTest methods, not on the `XCTestCase` subclass, when the suite overrides the Swift-declared `setUp() async throws` or `tearDown() async throws`. Those overrides must stay nonisolated, so the class-level annotation conflicts with them. Overrides of the Objective-C `setUp()`, `setUpWithError()` and `tearDown()` do not conflict: with a class-level `@MainActor` they stay nonisolated. Inside them, calls to Objective-C-imported main-actor API such as XCUI are silent in Swift 5 mode and warnings under complete checking, but a synchronous call to a Swift-declared `@MainActor` type is an error at every strictness level. An explicit `@MainActor` on such an override is a warning in Swift 5 mode and an error in Swift 6 mode. Move main-actor setup into `override func setUp() async throws`, or, when the setup must stay synchronous (XCUI typing does not register inside an async `setUp`), wrap it in `MainActor.assumeIsolated` as the UI test suites do. When the type under test is an actor, do not make the suite `@MainActor`. Make its mocks actors instead. See [catalog test isolation](https://github.com/woocommerce/woocommerce-ios/pull/18006).

The Xcode 27.1 SDK declares the async `setUp` and `tearDown` in Objective-C (`setUpWithCompletionHandler:`), so the conflict in the paragraph above does not occur with that SDK. On that toolchain (Swift 6.4), a class-level `@MainActor` suite that overrides `setUp() async throws` and `tearDown() async throws` has no diagnostics, in Swift 5 mode with complete checking and in Swift 6 mode. `CardPresentPaymentStoreTests` uses this form. `ProductStoreTests` uses it with an async `setUp` and passed CI on the pinned Xcode 27.0 in [#18160](https://github.com/woocommerce/woocommerce-ios/pull/18160). Swift 6 mode is not checked on Xcode 27.0. Before you move such a suite's `@MainActor` to its methods, reproduce the conflict on the pinned Xcode. See [WOOMOB-4185](https://linear.app/a8c/issue/WOOMOB-4185).

A class-level `@MainActor` on a subclass of a nonisolated Swift superclass compiles in Swift 6 mode as long as the subclass overrides nothing. The isolated designated initializer can call the nonisolated `super.init`, and stored closure properties such as `(XCUIApplication) -> XCUIElement` getters keep their nonisolated type while their bodies call main-actor XCTest API. The UI test screen objects use this with the Swift 5 `ScreenObject` package. Their callers in a Swift 5 mode target must become `@MainActor` in the same change, because a synchronous call to an isolated initializer or method from a nonisolated test method is an error at every strictness level. See [the UITestsFoundation migration](https://linear.app/a8c/issue/WOOMOB-4030).

When a protocol becomes `@MainActor`, its mocks infer main-actor isolation from the conformance. Synchronous XCTest methods that set mock properties then fail with errors, so add `@MainActor` to those methods in the same commit. Also write `@MainActor` on the mock class so the isolation is visible. Remove `@preconcurrency` from mock conformances that the isolated protocol makes unnecessary. See [the POS tab visibility checker](https://github.com/woocommerce/woocommerce-ios/pull/18034).

When a mock of a nonisolated, non-`Sendable` protocol defers a completion handler or a Combine `Future` promise with `DispatchQueue.main.async` or `asyncAfter`, each captured completion, promise, and `self` warns. If every caller reaches the mock on the main thread, make the mock `@MainActor` and declare an isolated conformance, such as `: @MainActor CardReaderService`. Replace the dispatch with `Task { @MainActor in }`, and use `try? await Task.sleep(for:)` for a delay. The main-actor class is `Sendable`, so a captured `self` does not warn. The completion and the promise stay in the main-actor region, so their captures do not warn. The shared protocol does not change. Make each suite that creates the mock `@MainActor`. Its synchronous `wait(for:)` calls still run the main-actor tasks. Before you choose this, trace how the store calls the mock: Combine sinks and `flatMap` closures run on the thread that emits. See `MockCardReaderService`, `MockNotificationsRemote`, and [WOOMOB-4185](https://linear.app/a8c/issue/WOOMOB-4185).

If a test waits for main-queue work with `DispatchQueue.main.async` and an expectation, the `@Sendable` closure warns for each captured value. If the code under test updates state synchronously when it is called on the main thread, such as through a `Thread.isMainThread` fast path, make the test `@MainActor` and read the state directly. Keep the wait if the update is always queued.

The guard also counts "cannot use struct 'Site' in a property declaration ... 'NetworkingCore' was not imported by this file". Fix it with a targeted import, such as `import struct NetworkingCore.Site`.

Keep tests that run work in parallel on purpose nonisolated. Examples are tests that use `concurrentPerform`, `async let`, or `TaskGroup`. Main-actor isolation stops the parallel execution that they test. Protect their shared state with a lock or `Mutex`. If a test depends on main-actor ordering, make that dependency explicit.

Construct UI fixtures inside a main-actor test or factory. Nonisolated XCTest setup is not suitable for their construction. Use computed fixtures to create separate mutable values for each test. Keep immutable `Sendable` fixtures shared when their identity or generated timestamp must remain constant. A computed property can return different test data on each read. See [the fixture review](https://github.com/woocommerce/woocommerce-ios/pull/17867#discussion_r4025136932).

A `static let` fixture of a non-`Sendable` type, such as Hardware's `Charge`, warns that it is not concurrency-safe. It also adds an "add '@preconcurrency'" warning for that module. A computed `static var` removes both warnings. `Hardware` is a module of this repository, so do not add `@preconcurrency import`.

In Swift Testing, `#expect(throws: Never.self) { #expect(try result.get() == expected) }` fails to compile with "errors thrown from here are not handled". Inside the closure, bind the value first (`let value = try result.get()`), then `#expect(value == expected)`, as in `AppSettingsStoreTests+ProductFilterHistory`.

When a protocol gains `Sendable`, check production and test conformers. Callback properties can need `@Sendable`. Build the code that creates these callbacks to check captured test state. Keep cleanup helpers compatible with their deinitializer isolation.

If a checked `Sendable` provider serializes a third-party service that has no sendability annotations, keep the unchecked boundary smaller than the provider. Put only the immutable service reference and queued operation in documented `@unchecked Sendable` containers, and continue routing every access through the existing serial executor. Make completion requirements `@Sendable` when the provider invokes them from that executor. This preserves compiler checking for the provider's own stored state and lets higher-level adaptors use checked `Sendable` conformance.

For a mutable mock of a `Sendable` protocol, use the first option that fits. Use a lock only when neither isolation option is possible:

1. A `@MainActor` class, when every requirement is `async` with `Sendable` arguments and results. A main-actor class is `Sendable`, keeps plain `var` spy state, and needs no other test changes. Make each suite that uses it `@MainActor` instead of adding a lock, unless the suite must stay nonisolated: it tests an actor or runs work in parallel on purpose (see above).
2. An `actor`, when the requirements are `async` with `Sendable` arguments and the tests can `await` reads. Tests cannot assign an actor's properties, so they set stubs through methods.
3. A `Mutex<State>`, when the mock has a synchronous requirement, a requirement with a non-`Sendable` argument or result, or a suite that must stay nonisolated and sets its state synchronously. An actor-isolated or main-actor-isolated witness for a non-`Sendable` argument such as `POSCart`, or a result such as `OrderNote`, warns with `NonSendableInAsyncConformanceOrOverride` (an error in Swift 6), and a synchronous requirement cannot have an isolated witness.

With a lock, protect the complete state operation. Separate locked getters and setters do not make a dictionary subscript update atomic. Return snapshots for reads. Use methods that change state under one lock. Copy callbacks while the lock is held. Release the lock before you invoke them. See [the addressed mock-state review](https://github.com/woocommerce/woocommerce-ios/pull/17974#discussion_r4152621462).

To check the intermediate state of a main-actor `@Observable` property, prefer the mock callback hook from `Modules/Tests/AGENTS.md`. Check the state inside the hook, and check the final state after the call. Also check that the mock was called, because a hook that does not run checks nothing. Do not use `withObservationTracking` with `MainActor.assumeIsolated` or with a `@Sendable` helper that captures mutable state. An observation recorder that reads the value in a `Task { @MainActor in }` needs a suspension between changes. It misses states if the mock is main-actor isolated or if `NonisolatedNonsendingByDefault` is on. The hook runs inside the call, so it does not depend on the executor. See `PointOfSaleOrderControllerTests` and [the review](https://github.com/woocommerce/woocommerce-ios/pull/18033).

When you replace test coordination, keep operations overlapping. Check duplicate requests, progress, and cancellation while the first operation is still running. Follow the callback-hook guidance in `Modules/Tests/AGENTS.md`. Paired readiness and suspension continuations can race. A main-actor annotation alone does not prove that a concurrent mock is safe. See [catalog test coverage](https://github.com/woocommerce/woocommerce-ios/pull/18006) and [concurrent mock requests](https://github.com/woocommerce/woocommerce-ios/pull/17974).

When a `Mutex` is necessary, a spy mock can keep its spy properties in a `Mutex<State>` and expose them through `@dynamicMemberLookup`, so the tests do not change. Constrain the subscript to `T: Sendable`. Without that constraint, the getter warns with "returning a 'WritableKeyPath' value as a 'sending' result". Each value written into the state, including method arguments that the spy records, must be `Sendable`. Otherwise the closure warns with "'inout sending' parameter '$0' is accessible ... at end of function". Make such argument types `Sendable` when the conformance is true, as for the `OrdersRemote` field enums. See `MockPOSOrderService`, `MockPOSOrdersRemote`, and the `@MainActor` mocks `MockPOSStaffFetcher`, `MockReceiptService`, and `MockPOSReceiptsRemote`.

`StorageManagerType` refines `Sendable`, so a helper that holds storage can become `Sendable` without changing its storage type. `any StorageManagerType & Sendable` is the same type, so new code does not need the composition. A `Store` subclass initializer with either spelling overrides `Store.init` and needs `override`, as in `StatsStoreV4`. Two PRs that each passed CI broke trunk this way: one added the composed initializer without `override`, and the other made the protocol `Sendable`. When a slice strengthens a widely used protocol, search for compositions with the same requirement, such as `& Sendable`, and rebuild on the latest trunk before merging. See `SettingStoreMethods` and `StatsStoreV4`.

## Payloads at callback boundaries

Inside the callback, extract the required `Sendable` IDs, values, or validated `Data`. Do this before you pass values to another actor or create child tasks. Keep non-`Sendable` notification models and type-erased containers in their original isolation context. Use the existing `RequestParameterValue` type for network parameters. Do not assume that `[String: Any]` is safe to send. See [notification loading](https://github.com/woocommerce/woocommerce-ios/pull/17954), [Watch payload snapshots](https://github.com/woocommerce/woocommerce-ios/pull/17950), and [typed request parameters](https://github.com/woocommerce/woocommerce-ios/pull/17370).

## Open base classes and locks

Swift checks a `Sendable` class conformance only on a `final` class whose superclass is `NSObject` or nothing. An `open` base class, such as `Remote`, can only be `@unchecked Sendable`. Its subclasses inherit the conformance, and the compiler does not check their stored properties. Before you add the conformance, list the stored properties of every subclass. Fix each `var` or non-`Sendable` value in the same change. A subclass of such a class cannot have a checked conformance either. In WOOMOB-4258, 6 of the 66 `Remote` subclasses had their own state, and 3 of them needed locks.

Make the base class's own stored properties `Sendable` `let`s, so that the only reason for `@unchecked` is that the class is not `final`. Replace `var` test seams with an internal initializer that tests call.

`NetworkingCore` and `WooFoundationCore` also build for the watch app (watchOS 9), so use `OSAllocatedUnfairLock` there. `Mutex` needs watchOS 11. For a lazy property, keep the optional value in the lock and create it inside `withLock`. For state that is not `Sendable`, such as `AnyCancellable`, use `OSAllocatedUnfairLock(uncheckedState:)` and `withLockUnchecked`. Create a Combine subscription outside the lock and store it afterwards, because a publisher can emit synchronously when you subscribe. A `Mutex` can hold non-`Sendable` closures, but each append and read then needs a `sending` value. Use an `NSLock` and a private `var` for that case, with an `@unchecked Sendable` conformance and a comment.

## Module flips and public constants

A public struct or enum gets no implicit `Sendable` conformance, even when every stored value is `Sendable`. Each `static let` of such a type then warns with "non-'Sendable' type may have shared mutable state". Declare `Sendable` on the type. In `WooFoundationCore`, this covered 14 of the module's 20 warnings (`ColorStudio` and `CurrencySettings.CurrencyPosition`).

The copied `Logging.swift` files read `CocoaLumberjackSwift.dynamicLogLevel`, a plain global `var` in CocoaLumberjack 3.8.5. A module in Swift 6 mode cannot reference it, and `@preconcurrency import` would only keep the warning. Make `defaultDebugLevel` a `let` set to `.all`, the library default, and remove `resetDefaultDebugLevel` when nothing calls it. Check the module's own `DDLog…` calls first: `WooFoundationCore` only logs errors, and the app sets `.verbose` at launch, so the threshold change is not observable. A module that logs at debug or verbose level needs a decision about its threshold before the flip.

Before you protect a debug-only static such as `BuildConfiguration.testingOverride`, search for callers, including `@testable` imports. An internal test seam with no callers is removed, not locked.
