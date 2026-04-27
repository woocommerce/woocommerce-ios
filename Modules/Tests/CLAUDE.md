# Testing Guidelines

## Framework
- **Prefer SwiftTesting over XCTest** for new tests, use `@Test` attribute and `#expect()` assertions
- When adding tests to an existing test class, follow that class's framework, naming, and testing approach

## Naming Conventions
Follow [naming-conventions.md](../../docs/naming-conventions.md#test-methods). Example:
- Use **snake_case** for test method names
- Pattern: `test_<operation>_when_<condition>_then_<expected_result>`

```swift
func test_loadOrders_when_error_occurs_then_shows_error_state()
func test_evolvePokemon_when_passed_a_Pikachu_then_it_returns_Raichu()
```

## Test Structure
Organize tests into three logical blocks with comments:

```swift
@Test func test_selectOrder_when_refunds_enabled_then_loads_refunds() async throws {
    // Given
    featureFlags.isRefundsEnabled = true
    let order = MockOrderService.makeOrder()

    // When
    await sut.selectOrder(order)

    // Then
    #expect(sut.refundsState.isLoaded)
}
```

## XCTest Async Rules
- Mark all `async` XCTest methods with `@MainActor` to prevent flaky failures from threading issues
- Use `storageManager.performAndSave({ storage in ... }, completion: {}, on: .main)` for all Core Data operations in tests — never use `storage.insertNewObject(...)` directly

## Async Testing Patterns
These patterns target modern Swift concurrency when using the Swift Testing framework.

### Choosing a pattern

| Situation | Use |
|---|---|
| Want to assert intermediate SUT state during an in-flight async call | Mock callback hook (see Mocks section) |
| Same as above, and the trigger awaits to completion in the test body | `confirmation()` wrapping the hook |
| Want to wait until an `@Observable` property reaches a value | `withCheckedContinuation` + `withObservationTracking` |
| Mock hook can fire more than once and you only want to act on the first | `fireOnce` (see `Modules/Tests/PointOfSaleTests/Helpers/FireOnce.swift`) |
| Combine subscription / observation re-establishment that may emit multiple events | `fireOnce` |

If the test contains `var resumed = false` to dedupe a callback, use `fireOnce` instead — the manual flag is racy when the closure runs off the test's actor.

### `confirmation()` for intermediate state observation

When the trigger is awaitable AND the hook fires before the trigger returns:

```swift
await confirmation { confirmation in
    catalogService.onLoadCatalogCalled = {
        #expect(sut.isLoading == true)
        confirmation()
    }

    // When
    await sut.loadCatalogData()
}
```

### `withObservationTracking` for `@Observable` properties

Wait for a property to reach a target value:

```swift
await withCheckedContinuation { continuation in
    withObservationTracking {
        _ = sut.observedState
    } onChange: {
        Task { @MainActor in
            // Task needed because onChange fires with willSet semantics
            if sut.observedState == .loaded {
                continuation.resume()
            }
        }
    }

    // When
    sut.load()
}
```

`withObservationTracking` is one-shot. If multiple state changes are expected before reaching the target, use `fireOnce` so the same closure can re-establish observation.

### `fireOnce` for multi-fire callbacks

When the SUT can trigger the same hook from more than one path (e.g., parallel observation handlers or multiple Tasks), the hook's `resume()` must be idempotent. Use `fireOnce` (the bug behind PR #16984 was a manual `var resumed = false` dedupe racing across actors):

```swift
await fireOnce { fire in
    coordinator.onPerformIncrementalSyncCalled = { fire() }
    Task { @MainActor in await sut.checkOut() }
}
```

The first call to `fire` resumes the underlying continuation; later calls are silent no-ops. Locking is internal, so the hook is safe to invoke from any actor.

## Mocks

### Naming
- Pattern: `Mock<ServiceName>` (e.g., `MockPOSOrderListService`)
- Location: Place mocks in a `Mocks/` subdirectory within the test target

### Structure
```swift
final class MockOrderService: OrderServiceProtocol {
    // Configuration
    var shouldThrowError = false
    var orderPages: [[Order]] = []

    // Spy properties for verification
    var loadOrderCalled = false
    var spyOrderID: Int64?

    // Stub return values
    var orderToReturn: Order?
    var errorToThrow: Error?
}
```

### Mock Callback Hooks for In-Flight Observation

When a test needs to assert state or mutate the SUT *while* it is awaiting the mock, expose a callback that the mock fires inside its body:

```swift
final class MockRefundsService: RefundsServiceProtocol {
    var loadOrderRefundsResultToReturn: [POSOrderRefund] = []
    var onLoadOrderRefundsCalled: (@MainActor (POSOrder) -> Void)?

    @MainActor
    func loadOrderRefunds(for order: POSOrder) async throws -> [POSOrderRefund] {
        onLoadOrderRefundsCalled?(order)
        return loadOrderRefundsResultToReturn
    }
}
```

The hook runs on the same actor as the SUT, so the test can call `sut.selectOrder(otherOrder)` or assert `sut.isLoading == true` synchronously inside the hook, then the mock returns and the SUT proceeds. No `Task`, no continuations, no race surface.

**When to mark the hook `@MainActor`:**
- The hook's body needs to call `@MainActor`-isolated SUT methods or read `@Observable` state — **required**.
- The hook only calls `fire()` from `fireOnce` and does no other work — optional, but match the type the SUT expects so closure literals don't need explicit isolation at the call site.
- Pin the **mock method itself** to `@MainActor` whenever the hook is `@MainActor`. That way the closure invocation is a same-actor call, no implicit hop, no need for `MainActor.run`.

For tests where the in-flight body itself needs to do async work, make the hook async:

```swift
var onSyncOrderCalled: (@MainActor () async -> Void)?

func syncOrder(...) async throws -> Order {
    await onSyncOrderCalled?()
    ...
}
```

If the hook can fire more than once (multiple SUT paths, observation re-emits), wrap the test's wait in `fireOnce` (see Async Testing Patterns above).

### Anti-Pattern: Mock Suspension via `awaitX` / `resumeX`

Do not write mocks that hold themselves open with one continuation while signalling readiness through a second one:

```swift
// DON'T
var shouldSuspend = false
func awaitServiceCall() async { ... stores call signal continuation ... }
func resumeService() { ... resumes suspension continuation ... }

func service(...) async {
    callSignalContinuation?.resume()                 // signal "I've been called"
    if shouldSuspend {
        await withCheckedContinuation { cont in
            suspensionContinuation = cont            // park HERE — too late
        }
    }
}
```

Why this hangs:

1. Test (on main) calls `await awaitServiceCall()`, stores its continuation on the mock, suspends.
2. SUT (on a Task in the cooperative pool) calls `service(...)`. Because the mock is non-isolated (no `@MainActor` annotation on the method), this call hops off main onto the pool.
3. From the pool, the mock executes `callSignalContinuation?.resume()`. That schedules the test to resume on main.
4. The test wakes on main and calls `resumeService()` — but the mock's pool thread hasn't yet executed `await withCheckedContinuation`, so `suspensionContinuation` is still `nil`. `?.resume()` silently no-ops.
5. The mock's pool thread finally reaches the `withCheckedContinuation`, stores the continuation, and parks. Nobody will ever resume it.
6. Test hangs until the job-level timeout (was 3 hours; see #16980).

Pinning the mock method to `@MainActor` removes the hop and makes the test pass, but only because main-actor source-order happens to schedule the writes before the reads. It papers over the underlying contract — the mock and the test are sharing mutable continuation state across actor isolation domains, which Swift's concurrency model does not guarantee to serialize. Use the callback hook pattern instead — the mock fires the hook **before returning**, so the test does its in-flight work inside the hook, with no second continuation in the picture. If the hook can fire more than once, wrap the wait in `fireOnce` (`Modules/Tests/PointOfSaleTests/Helpers/FireOnce.swift`).

### Cap Suite Runtime With `.timeLimit`

Add `@Suite(.timeLimit(.minutes(5)))` to any test suite that uses async patterns (continuations, callback hooks, `withObservationTracking`). A regression in this category fails as a single test in minutes instead of consuming a job-level timeout (the bug behind #16980 burned a 3-hour CI slot before this trait was in place).

Five minutes is the recommended cap because (a) Swift Testing's `.timeLimit` only accepts minute granularity, (b) any well-written test in this codebase finishes in well under a minute even on a loaded simulator, and (c) one minute is too aggressive for the slowest legitimate tests (Core Data migrations, simulator boot, contended cooperative pool under heavy parallel load) and would produce false failures. Don't drop the cap to 1 minute "to fail faster" without first confirming no legitimate test in the suite needs the headroom.

## Test Data Factories
Use static factory methods for consistent test data:

```swift
extension MockOrderService {
    static func makeOrder(id: Int64 = 1) -> Order {
        Order(id: id, status: .completed, ...)
    }
}
```

Or private helpers within test classes:

```swift
private extension OrderControllerTests {
    func makeOrder(id: Int64 = 1, status: OrderStatus = .completed) -> Order { ... }
}
```
