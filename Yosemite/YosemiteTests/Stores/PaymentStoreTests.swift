import TestKit
import XCTest
@testable import Networking
@testable import Yosemite

final class PaymentStoreTests: XCTestCase {
    /// Mock Dispatcher.
    private var dispatcher: Dispatcher!

    /// Mock Storage: InMemory.
    private var storageManager: MockStorageManager!

    /// Mock Network: Allows us to inject predefined responses.
    private var network: MockNetwork!

    private var remote: MockPaymentRemote!
    private var store: PaymentStore!

    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockStorageManager()
        network = MockNetwork()
        remote = MockPaymentRemote()
        store = PaymentStore(remote: remote, dispatcher: dispatcher, storageManager: storageManager, network: network)
    }

    override func tearDown() {
        store = nil
        remote = nil
        network = nil
        storageManager = nil
        dispatcher = nil
        super.tearDown()
    }

    // MARK: - `loadPlan`

    func test_loadPlan_returns_plan_on_success() throws {
        // Given
        remote.whenLoadingPlan(thenReturn: .success(.init(productID: 12, name: "woo", formattedPrice: "$16.8")))

        // When
        let result = waitFor { promise in
            self.store.onAction(PaymentAction.loadPlan(productID: 12) { result in
                promise(result)
            })
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let plan = try XCTUnwrap(result.get())
        XCTAssertEqual(plan, .init(productID: 12, name: "woo", formattedPrice: "$16.8"))
    }

    func test_loadPlan_returns_failure_on_error() throws {
        // Given
        remote.whenLoadingPlan(thenReturn: .failure(NetworkError.timeout))

        // When
        let result = waitFor { promise in
            self.store.onAction(PaymentAction.loadPlan(productID: 12) { result in
                promise(result)
            })
        }

        // Then
        XCTAssertTrue(result.isFailure)
        let error = try XCTUnwrap(result.failure)
        XCTAssertEqual(error as? NetworkError, .timeout)
    }

    // MARK: - `createCart`

    func test_createCart_returns_on_success() throws {
        // Given
        remote.whenCreatingCart(thenReturn: .success(()))

        // When
        let result = waitFor { promise in
            self.store.onAction(PaymentAction.createCart(productID: "12", siteID: 62) { result in
                promise(result)
            })
        }

        // Then
        XCTAssertTrue(result.isSuccess)
    }

    func test_createCart_returns_invalidProductID_error_when_productID_is_not_integer() throws {
        // Given
        remote.whenCreatingCart(thenReturn: .failure(NetworkError.timeout))

        // When
        let result = waitFor { promise in
            self.store.onAction(PaymentAction.createCart(productID: "wo0", siteID: 62) { result in
                promise(result)
            })
        }

        // Then
        XCTAssertTrue(result.isFailure)
        let error = try XCTUnwrap(result.failure)
        XCTAssertEqual(error as? Yosemite.CreateCartError, .invalidProductID)
    }

    func test_createCart_returns_failure_on_error() throws {
        // Given
        remote.whenCreatingCart(thenReturn: .failure(NetworkError.timeout))

        // When
        let result = waitFor { promise in
            self.store.onAction(PaymentAction.createCart(productID: "12", siteID: 62) { result in
                promise(result)
            })
        }

        // Then
        XCTAssertTrue(result.isFailure)
    }
}
