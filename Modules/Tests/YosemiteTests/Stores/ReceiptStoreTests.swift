import XCTest
import YosemiteTestHelpers
@testable import Yosemite
@testable import Storage
@testable import Networking
@testable import NetworkingCore

/// ReceiptStore Unit Tests
///
final class ReceiptStoreTests: XCTestCase {

    /// Mock Dispatcher!
    ///
    private var dispatcher: Dispatcher!

    /// Mock Storage: InMemory
    ///
    private var storageManager: MockStorageManager!

    /// Mock Network: Allows us to inject predefined responses!
    ///
    private var network: MockNetwork!

    /// Convenience Property: Returns the StorageType associated with the main thread.
    ///
    private var viewStorage: StorageType {
        return storageManager.viewStorage
    }

    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockStorageManager()
        network = MockNetwork()
    }

    override func tearDown() {
        dispatcher = nil
        storageManager = nil
        network = nil

        super.tearDown()
    }

    func test_retrieveReceipt_when_orderID_matches_route_then_returns_valid_receipt_with_expected_fields() throws {
        // Given
        let sampleOrderID: Int64 = 123
        let mockOrder = Order.fake().copy(orderID: sampleOrderID)
        let receiptStore = ReceiptStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network)
        let expectedReceiptURL = "https://mywootestingstore.com/wc/file/transient/7e811be40195b17f82604592ed26b694868807"
        let expectedReceiptExpirationDate = "2024-01-27"

        network.simulateResponse(requestUrlSuffix: "orders/\(sampleOrderID)/receipt", filename: "receipt")

        // When
        let expectedResult: Result<Receipt, Error> = waitFor { promise in
            let action = ReceiptAction.retrieveReceipt(order: mockOrder, onCompletion: { result in
                promise(result)
            })
            receiptStore.onAction(action)
        }

        // Then
        let expectedReceipt = try expectedResult.get()
        assertEqual(expectedReceiptURL, expectedReceipt.receiptURL)
        assertEqual(expectedReceiptExpirationDate, expectedReceipt.expirationDate)
    }

    func test_retrieveReceipt_when_orderID_does_not_match_route_then_returns_error() throws {
        // Given
        let sampleOrderID: Int64 = 987
        let mockOrder = Order.fake().copy(orderID: sampleOrderID)
        let receiptStore = ReceiptStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network)

        network.simulateResponse(requestUrlSuffix: "orders/123/receipt", filename: "receipt")

        // When
        let expectedResult: Result<Receipt, Error> = waitFor { promise in
            let action = ReceiptAction.retrieveReceipt(order: mockOrder, onCompletion: { result in
                promise(result)
            })
            receiptStore.onAction(action)
        }

        // Then
        let expectedError = expectedResult.failure
        XCTAssertNotNil(expectedError)
    }

    func test_sendReceipt_when_order_updates_and_action_succeeds() throws {
        // Given order update and send_order_details actions succeed
        let email = "test@test.com"
        let orderID: Int64 = 56
        let siteID: Int64 = 123
        let mockOrder = Order.fake().copy(siteID: siteID, orderID: orderID)
        let receiptStore = ReceiptStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network)
        network.simulateResponse(requestUrlSuffix: "orders/\(orderID)/actions/send_order_details", filename: "orders-actions-send-order-details")
        let mockProcessor = MockActionsProcessor()
        dispatcher.register(processor: mockProcessor, for: OrderAction.self)

        // When we send receipt to the given email
        let expectedResult: Result<Yosemite.Order, Error> = waitFor { promise in
            let action = ReceiptAction.sendReceipt(order: mockOrder, email: email) { result in
                promise(result)
            }
            receiptStore.onAction(action)
            if case let .updateOrder(_, order, _, _, _, onCompletion) = mockProcessor.receivedActions.first as? OrderAction {
                onCompletion(.success(order))
            }
        }

        // Then we expect a success result with the expected email set on the order
        let result = try expectedResult.get()
        XCTAssert(result.billingAddress?.email == email)
    }

    func test_sendReceipt_when_order_update_fails_then_send_receipt_fails() {
        // Given order update fails
        let email = "test@test.com"
        let orderID: Int64 = 56
        let siteID: Int64 = 123
        let mockOrder = Order.fake().copy(siteID: siteID, orderID: orderID)
        let receiptStore = ReceiptStore(dispatcher: dispatcher,
                                        storageManager: storageManager,
                                        network: network)
        let mockProcessor = MockActionsProcessor()
        dispatcher.register(processor: mockProcessor, for: OrderAction.self)

        // When we send receipt to the given email
        let expectedResult: Result<Yosemite.Order, Error> = waitFor { promise in
            let action = ReceiptAction.sendReceipt(order: mockOrder, email: email) { result in
                promise(result)
            }
            receiptStore.onAction(action)

            if case let .updateOrder(_, _, _, _, _, onCompletion) = mockProcessor.receivedActions.first as? OrderAction {
                onCompletion(.failure(OrderStatusError.missingSiteID))
            }
        }

        // Then we expect sendReceipt to fail
        XCTAssert(expectedResult.isFailure)
        XCTAssert(network.requestsForResponseData.isEmpty)
    }
}
