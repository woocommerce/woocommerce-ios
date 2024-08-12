import XCTest

@testable import WooCommerce

final class OrdersRouteTests: XCTestCase {
    private var deepLinkNavigator: MockDeepLinkNavigator!
    private var sut: OrdersRoute!

    override func setUp() {
        deepLinkNavigator = MockDeepLinkNavigator()
        sut = OrdersRoute(deepLinkNavigator: deepLinkNavigator)
    }

    func test_canHandle_returns_true_for_create_order_deep_link_path() {
        XCTAssertTrue(sut.canHandle(subPath: "orders/create"))
    }

    func test_canHandle_returns_true_for_order_list_deep_link_path() {
        XCTAssertTrue(sut.canHandle(subPath: "orders/"))
    }

    func test_performAction_forwards_orders_deep_link_to_orders_controller() throws {
        // Given
        let path = "orders"

        // When
        let reportedHandled = sut.perform(for: path, with: [:])

        // Then
        XCTAssertTrue(reportedHandled)
        let navigatedDestination = try XCTUnwrap(deepLinkNavigator.spyNavigatedDestination as? OrdersDestination)
        assertEqual(OrdersDestination.orderList, navigatedDestination)
    }

    func test_performAction_forwards_create_order_deep_link_to_orders_controller() throws {
        // Given
        let path = "orders/create"

        // When
        let reportedHandled = sut.perform(for: path, with: [:])

        // Then
        XCTAssertTrue(reportedHandled)
        let navigatedDestination = try XCTUnwrap(deepLinkNavigator.spyNavigatedDestination as? OrdersDestination)
        assertEqual(OrdersDestination.createOrder, navigatedDestination)
    }

    func test_performAction_does_not_forward_unrecognised_deep_link_to_hub_menu() {
        // Given
        let path = "orders/some-future-feature"

        // When
        let reportedHandled = sut.perform(for: path, with: [:])

        // Then
        XCTAssertFalse(reportedHandled)
        XCTAssertFalse(deepLinkNavigator.spyDidNavigate)
    }
}
