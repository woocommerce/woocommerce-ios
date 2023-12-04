import XCTest

@testable import WooCommerce

final class PaymentsRouteTests: XCTestCase {

    private var deepLinkNavigator: MockDeepLinkNavigator!
    private var sut: PaymentsRoute!

    override func setUp() {
        deepLinkNavigator = MockDeepLinkNavigator()
        sut = PaymentsRoute(deepLinkNavigator: deepLinkNavigator)
    }

    func test_canHandle_returns_true_for_set_up_tap_to_pay_deep_link_path() {
        XCTAssertTrue(sut.canHandle(subPath: "payments/tap-to-pay"))
    }

    func test_canHandle_returns_true_for_payments_menu_deep_link_path() {
        XCTAssertTrue(sut.canHandle(subPath: "payments"))
    }

    func test_canHandle_returns_true_for_collect_payment_deep_link_path() {
        XCTAssertTrue(sut.canHandle(subPath: "payments/collect-payment"))
    }

    func test_performAction_forwards_payments_deep_link_to_hub_menu() throws {
        // Given
        let path = "payments"

        // When
        let reportedHandled = sut.perform(for: path, with: [:])

        // Then
        XCTAssertTrue(reportedHandled)
        let navigatedDestination = try XCTUnwrap(deepLinkNavigator.spyNavigatedDestination as? HubMenuDestination)
        assertEqual(HubMenuDestination.paymentsMenu, navigatedDestination)
    }

    func test_performAction_forwards_tap_to_pay_deep_link_to_hub_menu() throws {
        // Given
        let path = "payments/tap-to-pay"

        // When
        let reportedHandled = sut.perform(for: path, with: [:])

        // Then
        XCTAssertTrue(reportedHandled)
        let navigatedDestination = try XCTUnwrap(deepLinkNavigator.spyNavigatedDestination as? PaymentsMenuDestination)
        assertEqual(PaymentsMenuDestination.tapToPay, navigatedDestination)
    }

    func test_performAction_forwards_collect_payment_deep_link_to_hub_menu() throws {
        // Given
        let path = "payments/collect-payment"

        // When
        let reportedHandled = sut.perform(for: path, with: [:])

        // Then
        XCTAssertTrue(reportedHandled)
        let navigatedDestination = try XCTUnwrap(deepLinkNavigator.spyNavigatedDestination as? PaymentsMenuDestination)
        assertEqual(PaymentsMenuDestination.collectPayment, navigatedDestination)
    }

    func test_performAction_does_not_forward_unrecognised_deep_link_to_hub_menu() {
        // Given
        let path = "payments/some-future-feature"

        // When
        let reportedHandled = sut.perform(for: path, with: [:])

        // Then
        XCTAssertFalse(reportedHandled)
        XCTAssertFalse(deepLinkNavigator.spyDidNavigate)
    }

}
