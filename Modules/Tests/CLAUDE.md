# Testing Guidelines

## Framework
- **Prefer SwiftTesting over XCTest** for new tests, use `@Test` attribute and `#expect()` assertions
- Match the existing style when adding tests to an existing test class

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

## Async Testing Patterns

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

### Continuation-Based Mocks for Async Control
```swift
final class MockRefundsService: RefundsServiceProtocol {
    private var continuation: CheckedContinuation<Void, Never>?

    var shouldSuspend = false

    func awaitServiceCall() async {
        await withCheckedContinuation { cont in
            continuation = cont
        }
    }

    func resumeService() {
        continuation?.resume()
        continuation = nil
    }
}
```

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
