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
        "-AppleLanguages",
        "(en)",
        "-AppleLocale",
        "en_US",
        // APIMocks does not stub mobile/feature-flags; override the remote POS flag to keep launch deterministic.
        "-com.woocommerce.featureflag.override.remote.pointOfSale",
        "YES",
        // Keep POS UI tests focused on POS behavior instead of rollout country/tab visibility gates.
        "bypass-pos-tab-visibility-checks"
    ]

    private static let checkoutLaunchArguments = [
        "bypass-pos-eligibility-checks",
        "use-pos-ui-test-mocks"
    ]

    private static let customAmountsLaunchArguments = [
        "-com.woocommerce.featureflag.override.pointOfSaleCustomAmounts",
        "YES"
    ]

    // The UI-test card payment mock starts disconnected so POS exposes the Card reader CTA.
    // Tap to Pay is gated first on `PaymentCardReader.isSupported` (Apple's ProximityReader),
    // which is false on simulators, so `POSTapToPayAvailabilityChecker` denies before it ever
    // reaches Stripe's device-support check — including Stripe's simulated Tap to Pay reader.
    // The CTA is therefore the Bluetooth card reader path.
    private static let simulatedReaderLaunchArguments = [
        "use-mocked-card-present-payment",
        "-simulate-stripe-card-reader"
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
            .tapBackToProductSelectorFromCheckout()
            .verifyReturnedFromCheckoutToProductSelector(variationID: ProductIDs.variation)
            .tapCheckout()
            .waitForTotalsLoaded()
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

    func test_POS_eligible_site_can_search_manage_cart_open_settings_and_exit_POS() throws {
        try openPOS(extraLaunchArguments: Self.customAmountsLaunchArguments)
            .tapSearchProducts()
            .enterSearchTerm("Rose")
            .tapAddProduct(productID: ProductIDs.simpleProduct)
            .dismissSearch()
            .verifyCartItemCount(1)
            .dismissCompactCartIfNeeded()
            .tapAddProduct(productID: ProductIDs.simpleProduct)
            .verifyCartItemCount(2)
            .dismissCompactCartIfNeeded()
            .tapAddCustomAmount(amount: "12.34")
            .verifyCartContainsProduct(productID: ProductIDs.simpleProduct)
            .verifyCartItemCount(3)
            .verifyCartContainsCustomAmount()
            .removeProductFromCart(productID: ProductIDs.simpleProduct, remainingCartItemCount: 2)
            .removeCustomAmountFromCart()
            .verifyCartContainsProduct(productID: ProductIDs.simpleProduct)
            .verifyCartItemCount(1)
            .dismissCompactCartIfNeeded()
            .tapMenuButton()
            .tapSettingsMenuItem()
            .verifySettingsVisible()
            .dismissSettings()
            .tapMenuButton()
            .tapExitMenuItem()
            .confirmExitPOS()
    }

    private func beginTwoProductCheckout(extraLaunchArguments: [String] = []) throws -> POSScreen {
        return try openPOS(extraLaunchArguments: extraLaunchArguments)
            .tapAddProduct(productID: ProductIDs.simpleProduct)
            .tapAddVariation(parentProductID: ProductIDs.variableProduct, variationID: ProductIDs.variation)
            .verifyCartContainsProduct(productID: ProductIDs.simpleProduct)
            .verifyCartContainsVariation(variationID: ProductIDs.variation)
            .tapCheckout()
            .waitForTotalsLoaded()
    }

    private func openPOS(extraLaunchArguments: [String] = []) throws -> POSScreen {
        try launchAndLogin(extraLaunchArguments: Self.checkoutLaunchArguments + extraLaunchArguments)

        return try TabNavComponent()
            .goToPOSScreen()
    }

    private func launchAndLogin(extraLaunchArguments: [String] = []) throws {
        let app = XCUIApplication()
        app.launchArguments = Self.baseLaunchArguments + extraLaunchArguments
        app.launch()

        try LoginFlow.login()
    }
}
