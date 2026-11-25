import UITestsFoundation
import XCTest

@MainActor
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

    private static let rolesLaunchArguments = [
        "-com.woocommerce.featureflag.override.pointOfSaleRoles",
        "YES"
    ]

    private static let testPIN = ["1", "3", "6", "8"]
    private static let unlockTitle = "Enter your PIN to unlock POS"

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

    func test_POS_cold_launch_keeps_ineligibility_behind_the_saved_lock() throws {
        // Given
        let app = XCUIApplication()
        let screen = try openPOS(extraLaunchArguments: Self.rolesLaunchArguments)
        setUpAdminPIN(in: app, from: screen)
        lockInBackground(app)

        // When the persisted lock is restored and eligibility is checked again.
        app.terminate()
        app.launchArguments = Self.baseLaunchArguments.filter { $0 != "logout-at-launch" } + Self.rolesLaunchArguments
        app.launch()

        // Then
        XCTAssertTrue(app.staticTexts[Self.unlockTitle].waitForExistence(timeout: 15))
        XCTAssertFalse(app.staticTexts["pos-ineligible-unsupported-woocommerce-version-suggestion"].exists)
        XCTAssertFalse(app.buttons["pos-product-card-1"].isHittable)
        enterPIN(in: app, after: Self.unlockTitle)
        try POSIneligibleScreen().verifyUnsupportedWooCommerceVersion().tapExitPOS()
    }

    func test_POS_background_lock_and_rotation_hide_the_current_sale_until_unlock() throws {
        // Given
        let app = XCUIApplication()
        let device = XCUIDevice.shared
        device.orientation = .portrait
        defer { device.orientation = .portrait }
        let screen = try openPOS(extraLaunchArguments: Self.rolesLaunchArguments)
        setUpAdminPIN(in: app, from: screen)
        lockInBackground(app)
        enterPIN(in: app, after: Self.unlockTitle)
        screen.tapAddProduct(productID: ProductIDs.simpleProduct)
            .verifyCartContainsProduct(productID: ProductIDs.simpleProduct)
            .verifyCartItemCount(1)

        // When
        lockInBackground(app)
        device.orientation = .landscapeLeft

        // Then
        XCTAssertTrue(app.staticTexts[Self.unlockTitle].waitForExistence(timeout: 10))
        let cartItem = app.descendants(matching: .any)["pos-cart-item-product-\(ProductIDs.simpleProduct)"]
        XCTAssertFalse(cartItem.exists)
        XCTAssertFalse(app.buttons["pos-product-card-1"].isHittable)
        device.orientation = .portrait
        enterPIN(in: app, after: Self.unlockTitle)
        XCTAssertTrue(app.buttons["pos-product-card-1"].waitForExistence(timeout: 10))
        screen.verifyCartContainsProduct(productID: ProductIDs.simpleProduct).verifyCartItemCount(1)
    }

    // Skipped in UITests.xctestplan. On iPhone, after the custom amount flow closes, XCUITest taps the compact cart
    // button at the center of the screen (201, 437) instead of at the button, which opens a product. Waiting for a stable
    // frame did not help.
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

    private func setUpAdminPIN(in app: XCUIApplication, from screen: POSScreen) {
        screen.tapMenuButton().tapSettingsMenuItem().verifySettingsVisible()
        let security = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Security,")).firstMatch
        XCTAssertTrue(security.waitForExistence(timeout: 10))
        security.tap()

        let getStarted = app.buttons["pos-security-get-started"]
        guard getStarted.waitForExistence(timeout: 5) else { return }
        getStarted.tap()
        enterPIN(in: app, after: "Choose your admin PIN")
        enterPIN(in: app, after: "Confirm your admin PIN")
        let continueButton = app.buttons["Continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 10))
        continueButton.tap()
        let maybeLater = app.buttons["Maybe later"]
        XCTAssertTrue(maybeLater.waitForExistence(timeout: 10))
        maybeLater.tap()
        XCTAssertTrue(maybeLater.waitForNonExistence(timeout: 10))
    }

    private func lockInBackground(_ app: XCUIApplication) {
        XCUIDevice.shared.press(.home)
        app.activate()
        XCTAssertTrue(app.staticTexts[Self.unlockTitle].waitForExistence(timeout: 10))
    }

    private func enterPIN(in app: XCUIApplication, after title: String) {
        XCTAssertTrue(app.staticTexts[title].waitForExistence(timeout: 10))
        for digit in Self.testPIN {
            let key = app.buttons[digit]
            XCTAssertTrue(key.wait(for: \.isHittable, toEqual: true, timeout: 10))
            key.tap()
        }
    }
}
