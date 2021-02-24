import XCTest
import Yosemite
import Combine

@testable import WooCommerce

/// Unit tests for `OrderFulfillmentUseCase`.
final class OrderFulfillmentUseCaseTests: XCTestCase {

    private var stores: MockStoresManager!
    private var cancellables = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()
        stores = MockStoresManager(sessionManager: SessionManager.makeForTesting())
        cancellables = Set<AnyCancellable>()
    }

    override func tearDown() {
        cancellables.forEach {
            $0.cancel()
        }
        stores = nil
        super.tearDown()
    }

    func test_fulfill_dispatches_an_Action_to_change_the_status_to_completed() throws {
        // Given
        let order = MockOrders().empty().copy(siteID: 1_900, orderID: 981, status: .processing)
        let useCase = OrderFulfillmentUseCase(order: order, stores: stores)

        // When
        let process = useCase.fulfill()

        // Then
        XCTAssertEqual(process.activity, .fulfill)
        XCTAssertEqual(stores.receivedActions.count, 1)
        let action = try XCTUnwrap(stores.receivedActions.first as? OrderAction)
        assertThat(statusUpdateAction: action, matches: order, status: .completed)
    }

    func test_undo_dispatches_an_Action_to_change_the_status_back() throws {
        // Given
        let order = MockOrders().empty().copy(siteID: 98, orderID: 12, status: .failed)
        let useCase = OrderFulfillmentUseCase(order: order, stores: stores)

        let process = useCase.fulfill()

        // When
        let undoProcess = process.undo()

        // Then
        XCTAssertEqual(undoProcess.activity, .undo)
        XCTAssertEqual(stores.receivedActions.count, 2)

        let action = try XCTUnwrap(stores.receivedActions.last as? OrderAction)
        assertThat(statusUpdateAction: action, matches: order, status: .failed)
    }

    func test_retry_dispatches_an_Action_to_change_the_status_to_completed() throws {
        // Given
        let order = MockOrders().empty().copy(siteID: 498, orderID: 29, status: .pending)
        let useCase = OrderFulfillmentUseCase(order: order, stores: stores)

        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            guard case let .updateOrder(siteID: _, orderID: _, status: status, onCompletion: onCompletion) = action else {
                XCTFail("Unexpected action \(action).")
                return
            }

            switch status {
            case .completed:
                onCompletion(SampleError.first)
            default:
                onCompletion(nil)
            }
        }

        let process = useCase.fulfill()
        let retry: () -> OrderFulfillmentUseCase.FulfillmentProcess = waitFor { promise in
            process.result.sink { completion in
                guard case let .failure(error: fulfillmentError) = completion else {
                    XCTFail("Unexpected completion \(completion).")
                    return
                }

                promise(fulfillmentError.retry)
            } receiveValue: {
                // noop
            }.store(in: &self.cancellables)
        }

        // When
        let retryProcess = retry()

        // Then
        XCTAssertEqual(retryProcess.activity, .fulfill)
        XCTAssertEqual(stores.receivedActions.count, 2)

        let action = try XCTUnwrap(stores.receivedActions.last as? OrderAction)
        assertThat(statusUpdateAction: action, matches: order, status: .completed)
    }

    func test_fulfill_returns_an_Error_if_the_Action_fails() throws {
        // Given
        let order = MockOrders().empty().copy(siteID: 500, orderID: 1, status: .pending)
        let useCase = OrderFulfillmentUseCase(order: order, stores: stores)

        mockUpdateOrderAction(from: stores, toCompleteWithError: SampleError.first)

        // When
        let process = useCase.fulfill()
        let error: OrderFulfillmentUseCase.FulfillmentError = waitFor { promise in
            process.result.sink { completion in
                guard case let .failure(error: fulfillmentError) = completion else {
                    XCTFail("Unexpected completion \(completion).")
                    return
                }

                promise(fulfillmentError)
            } receiveValue: {
                // noop
            }.store(in: &self.cancellables)
        }

        // Then
        XCTAssertEqual(error.activity, .fulfill)
        XCTAssertEqual(error.message, OrderFulfillmentUseCase.Localization.fulfillmentError(orderID: order.orderID))
    }

    func test_fulfill_finishes_with_no_Error_if_the_Action_succeeds() throws {
        // Given
        let order = MockOrders().empty().copy(siteID: 500, orderID: 1, status: .pending)
        let useCase = OrderFulfillmentUseCase(order: order, stores: stores)

        mockUpdateOrderAction(from: stores, toCompleteWithError: nil)

        // When
        let process = useCase.fulfill()

        // Then
        waitForExpectation { expectation in
            process.result.sink { completion in
                if case .finished = completion {
                    expectation.fulfill()
                }
            } receiveValue: {
                // noop
            }.store(in: &self.cancellables)
        }
    }
}

private extension OrderFulfillmentUseCaseTests {

    func assertThat(statusUpdateAction: OrderAction,
                    matches order: Order,
                    status expectedStatus: OrderStatusEnum,
                    file: StaticString = #file,
                    line: UInt = #line) {

        guard case let .updateOrder(siteID: siteID, orderID: orderID, status: actualStatus, onCompletion: _) = statusUpdateAction else {
            XCTFail("Expected \(statusUpdateAction) to be \(OrderAction.self).updateOrder.", file: file, line: line)
            return
        }

        XCTAssertEqual(siteID, order.siteID, file: file, line: line)
        XCTAssertEqual(orderID, order.orderID, file: file, line: line)
        XCTAssertEqual(actualStatus, expectedStatus, file: file, line: line)
    }

    func mockUpdateOrderAction(from stores: MockStoresManager,
                               toCompleteWithError completionError: Error?,
                               file: StaticString = #file,
                               line: UInt = #line) {
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            guard case let .updateOrder(siteID: _, orderID: _, status: _, onCompletion: onCompletion) = action else {
                XCTFail("Unexpected action \(action).", file: file, line: line)
                return
            }

            onCompletion(completionError)
        }
    }
}
