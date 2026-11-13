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

### 1. Continuations for Mock Callbacks
Use `withCheckedContinuation` to wait for mock method invocations:

```swift
await withCheckedContinuation { continuation in
    cardPresentPaymentService.onCollectPaymentCalled = {
        continuation.resume()
    }

    // When
    cardPresentPaymentService.connectedReader = .init(name: "Reader", batteryLevel: 0.7)
}
```

### 2. `confirmation()` for Intermediate State Observation
Use when testing state changes during an async operation:

```swift
await confirmation() { confirmation in
    catalogService.onLoadCatalogCalled = {
        #expect(sut.isLoading == true)
        confirmation()
    }

    // When
    await sut.loadCatalogData()
}
```

### 3. `withObservationTracking` for @Observable Properties
Use `withCheckedContinuation` + `withObservationTracking` to wait for `@Observable` state changes. This works for both sync and async methods:

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

**Key points:**
- `withObservationTracking` detects property changes deterministically (no polling)
- Wrap the state check in `Task { @MainActor in }` because `onChange` fires with `willSet` semantics
- The continuation suspends until the expected state is reached

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

When a test needs to assert state or mutate the SUT *while* it is awaiting the mock, expose a callback that the mock fires inside its body, before returning:

```swift
final class MockRefundsService: RefundsServiceProtocol {
    var resultToReturn: [Refund] = []
    var onLoadCalled: (@MainActor (Order) -> Void)?

    @MainActor
    func load(for order: Order) async throws -> [Refund] {
        onLoadCalled?(order)
        return resultToReturn
    }
}
```

The hook runs on the same actor as the SUT, so the test can synchronously mutate state or assert intermediate values inside the hook, then the mock returns and the SUT proceeds. No `Task`, no continuations, no race surface. Mark the hook `@MainActor` whenever the SUT it touches is `@MainActor`-isolated, and pin the mock method itself to `@MainActor` to keep the invocation a same-actor call.

For tests where the in-flight body itself needs to do async work, make the hook async:

```swift
var onSyncCalled: (@MainActor () async -> Void)?

func sync(...) async throws {
    await onSyncCalled?()
    ...
}
```

### Anti-Pattern: Mock Suspension via `awaitX` / `resumeX`

Do not write mocks that hold themselves open with one continuation while signalling readiness through a second one. The two continuations are written and read from different actors, so the test's `resumeX` can fire before the mock has stored the suspension continuation, leaving the mock parked on a continuation no one will resume — the test hangs. Use the callback hook pattern above instead.

### Cap Suite Runtime With `.timeLimit`

Add `@Suite(.timeLimit(.minutes(5)))` to test suites that use async patterns (continuations, callback hooks, `withObservationTracking`). A regression in this category fails as a single test in minutes instead of consuming a job-level timeout. Five minutes is recommended because Swift Testing's `.timeLimit` only accepts minute granularity, well-written tests finish in well under a minute, and one minute is too tight for the slowest legitimate tests (Core Data migrations, simulator boot, contended cooperative pool under heavy parallel load).

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
