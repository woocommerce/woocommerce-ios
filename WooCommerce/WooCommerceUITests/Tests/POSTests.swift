import UITestsFoundation
import XCTest

final class POSTests: XCTestCase {
    private enum ProductIDs {
        static let simpleProduct = 1
        static let variableProduct = 4
        static let variation = 401
    }

    private static let baseLaunchArguments = [
        "logout-at-launch",
        "disable-animations",
        "mocked-wpcom-api",
        "-ui_testing",
        // APIMocks does not stub mobile/feature-flags; override the remote POS flag to keep launch deterministic.
        "-com.woocommerce.featureflag.override.remote.pointOfSale",
        "YES"
    ]

    private static let checkoutLaunchArguments = [
        "bypass-pos-eligibility-checks",
        "use-pos-ui-test-mocks"
    ]

    // The UI-test card payment mock starts disconnected so POS exposes the Card reader CTA.
    private static let simulatedReaderLaunchArguments = [
        "use-mocked-card-present-payment",
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
            .tapExitPOS()
    }

    func test_POS_eligible_site_can_complete_cash_payment_and_start_new_order() throws {
        try beginTwoProductCheckout()
            .tapCashPayment()
            .tapMarkPaymentComplete()
            .waitForPaymentSuccess()
            .tapNewOrder()
            .verifyReadyForNewOrder(previousProductID: ProductIDs.simpleProduct, previousVariationID: ProductIDs.variation)
    }

    func test_POS_eligible_site_can_complete_card_payment_with_simulated_reader_and_start_new_order() throws {
        try beginTwoProductCheckout(extraLaunchArguments: Self.simulatedReaderLaunchArguments)
            .tapCardReaderPayment()
            .waitForCardPaymentStartedOrSucceeded()
            .waitForPaymentSuccess()
            .tapNewOrder()
            .verifyReadyForNewOrder(previousProductID: ProductIDs.simpleProduct, previousVariationID: ProductIDs.variation)
    }

    private func beginTwoProductCheckout(extraLaunchArguments: [String] = []) throws -> POSScreen {
        try launchAndLogin(extraLaunchArguments: Self.checkoutLaunchArguments + extraLaunchArguments)

        return try TabNavComponent()
            .goToPOSScreen()
            .tapAddProduct(productID: ProductIDs.simpleProduct)
            .tapAddVariation(parentProductID: ProductIDs.variableProduct, variationID: ProductIDs.variation)
            .verifyCartContainsProduct(productID: ProductIDs.simpleProduct)
            .verifyCartContainsVariation(variationID: ProductIDs.variation)
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
