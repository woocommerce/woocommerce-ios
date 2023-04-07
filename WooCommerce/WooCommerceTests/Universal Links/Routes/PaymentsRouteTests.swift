import XCTest
import TestKit
@testable import WooCommerce

final class PaymentsRouteTests: XCTestCase {

    var deepLinkForwarder: MockDeepLinkForwarder!
    var sut: PaymentsRoute!

    override func setUp() {
        deepLinkForwarder = MockDeepLinkForwarder()
        sut = PaymentsRoute(deepLinkForwarder: deepLinkForwarder)
    }

    func test_canHandle_true_for_set_up_tap_to_pay() {
        XCTAssertTrue(sut.canHandle(subPath: "payments/tap-to-pay"))
    }

    func test_canHandle_true_for_payments_menu() {
        XCTAssertTrue(sut.canHandle(subPath: "payments"))
    }

    func test_canHandle_true_for_collect_payment() {
        XCTAssertTrue(sut.canHandle(subPath: "payments/collect-payment"))
    }

    func test_performAction_payments_deep_link_forwarded() {
        // Given
        let path = "payments"

        // When
        let reportedHandled = sut.perform(for: path, with: [:])

        // Then
        XCTAssertTrue(reportedHandled)
        assertEqual(HubMenuCoordinator.DeepLinkDestination.paymentsMenu, deepLinkForwarder.spyForwardedHubMenuDeepLink)
    }

    func test_performAction_tap_to_pay_deep_link_forwarded() {
        // Given
        let path = "payments/tap-to-pay"

        // When
        let reportedHandled = sut.perform(for: path, with: [:])

        // Then
        XCTAssertTrue(reportedHandled)
        assertEqual(HubMenuCoordinator.DeepLinkDestination.tapToPayOnIPhone, deepLinkForwarder.spyForwardedHubMenuDeepLink)
    }

    func test_performAction_collect_payment_deep_link_forwarded() {
        // Given
        let path = "payments/collect-payment"

        // When
        let reportedHandled = sut.perform(for: path, with: [:])

        // Then
        XCTAssertTrue(reportedHandled)
        assertEqual(HubMenuCoordinator.DeepLinkDestination.simplePayments, deepLinkForwarder.spyForwardedHubMenuDeepLink)
    }

    func test_performAction_unrecognised_path_no_deep_link_forwarded() {
        // Given
        let path = "payments/some-future-feature"

        // When
        let reportedHandled = sut.perform(for: path, with: [:])

        // Then
        XCTAssertFalse(reportedHandled)
        XCTAssertFalse(deepLinkForwarder.spyDidForwardHubMenuDeepLink)
    }

}
