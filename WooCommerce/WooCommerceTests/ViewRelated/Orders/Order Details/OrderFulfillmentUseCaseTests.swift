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
    }

    override func tearDown() {
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
}
