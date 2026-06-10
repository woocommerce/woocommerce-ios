import UITestsFoundation
import XCTest

final class POSTests: XCTestCase {
    private static let baseLaunchArguments = [
        "logout-at-launch",
        "disable-animations",
        "mocked-wpcom-api",
        "-ui_testing",
        // APIMocks does not stub mobile/feature-flags; override the remote POS flag to keep launch deterministic.
        "-com.woocommerce.featureflag.override.remote.pointOfSale",
        "YES"
    ]

    // Start disconnected so POS exposes the Card reader CTA while screenshot flows keep the mock connected by default.
    private static let disconnectedSimulatedReaderLaunchArguments = [
        "use-mocked-card-present-payment",
        "start-mocked-card-present-payment-disconnected",
        "-simulate-stripe-card-reader",
        "-com.woocommerce.featureflag.override.pointOfSaleTapToPay",
        "NO"
    ]

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func test_POS_displays_unsupported_WooCommerce_version_when_site_fails_plugin_eligibility() throws {
        try launchAndLogin()

        try TabNavComponent()
            .goToPOSIneligibleScreen()
            .verifyUnsupportedWooCommerceVersion()
    }

    func test_POS_eligible_site_can_complete_cash_payment_and_start_new_order() throws {
        try beginTwoProductCheckout()
            .tapCashPayment()
            .tapMarkPaymentComplete()
            .waitForPaymentSuccess()
            .tapNewOrder()
            .verifyReadyForNewOrder()
    }

    func test_POS_eligible_site_can_complete_card_payment_with_simulated_reader_and_start_new_order() throws {
        try beginTwoProductCheckout(extraLaunchArguments: Self.disconnectedSimulatedReaderLaunchArguments)
            .tapCardReaderPayment()
            .waitForCardPaymentStartedOrSucceeded()
            .waitForPaymentSuccess()
            .tapNewOrder()
            .verifyReadyForNewOrder()
    }

    private func beginTwoProductCheckout(extraLaunchArguments: [String] = []) throws -> POSScreen {
        try launchAndLogin(extraLaunchArguments: ["bypass-pos-eligibility-checks"] + extraLaunchArguments)

        return try TabNavComponent()
            .goToPOSScreen()
            .tapAddProduct(productID: 2130)
            .tapAddProduct(productID: 2131)
            .verifyCartContainsProduct(productID: 2130)
            .verifyCartContainsProduct(productID: 2131)
            .tapCheckout()
            .waitForTotalsLoaded()
    }

    private func launchAndLogin(extraLaunchArguments: [String] = []) throws {
        let app = XCUIApplication()
        app.launchArguments = Self.baseLaunchArguments + extraLaunchArguments
        app.launch()

        try LoginFlow.login()
    }
}
