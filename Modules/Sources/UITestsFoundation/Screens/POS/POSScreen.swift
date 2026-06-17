import Foundation
import ScreenObject
import XCTest
// periphery: ignore - used for UI testing
public final class POSScreen: ScreenObject {
    private let firstProductCardGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["pos-product-card-1"]
    }
    private let cartViewGetter: (XCUIApplication) -> XCUIElement = {
        $0.otherElements["pos-cart-view"]
    }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [firstProductCardGetter],
            app: app,
            waitTimeout: 60
        )
    }

    @discardableResult
    public func tapAddProduct(productID: Int) -> Self {
        let productButton = app.buttons["pos-product-card-\(productID)"]

        XCTAssertTrue(productButton.waitForIsHittable(timeout: 15), "Product \(productID) should be tappable in POS.")
        productButton.tap()

        return self
    }

    @discardableResult
    public func tapAddVariation(parentProductID: Int, variationID: Int) -> Self {
        let parentProductButton = app.buttons["pos-variable-product-card-\(parentProductID)"]
        parentProductButton.scrollIntoView(app: app)
        XCTAssertTrue(parentProductButton.waitForIsHittable(timeout: 5), "Variable product \(parentProductID) should be tappable in POS.")
        parentProductButton.tap()

        let variationButton = app.buttons["pos-variation-card-\(variationID)"]
        variationButton.scrollIntoView(app: app)
        XCTAssertTrue(variationButton.waitForIsHittable(timeout: 5), "Variation \(variationID) should be tappable in POS.")
        variationButton.tap()

        return self
    }

    @discardableResult
    public func tapSearchProducts() -> Self {
        let searchButton = app.buttons["pos-search-button"]
        XCTAssertTrue(searchButton.waitForIsHittable(timeout: 10), "POS search button should be tappable.")
        searchButton.tap()
        return self
    }

    @discardableResult
    public func enterSearchTerm(_ term: String) -> Self {
        let searchField = app.textFields["pos-search-field"]
        XCTAssertTrue(searchField.waitForIsHittable(timeout: 10), "POS search field should be tappable.")
        searchField.tap()
        searchField.typeText(term)
        return self
    }

    @discardableResult
    public func dismissSearch() -> Self {
        let searchField = app.textFields["pos-search-field"]
        let searchButton = app.buttons["pos-search-button"]
        guard waitForVisibleElement(searchField, timeout: 1), !searchButton.isHittable else {
            return self
        }

        let searchBackButton = app.buttons["pos-search-back-button"]
        if searchBackButton.waitForIsHittable(timeout: 5) {
            searchBackButton.tap()
            return self
        }

        if waitForVisibleElement(searchBackButton, timeout: 2) {
            searchBackButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        } else {
            // iPad can keep the symbol-only close affordance out of the accessibility tree.
            // Tap the expected close affordance position relative to the visible search field.
            searchField.coordinate(withNormalizedOffset: CGVector(dx: -0.08, dy: 0.5)).tap()
        }
        XCTAssertTrue(searchButton.waitForIsHittable(timeout: 10), "POS search should be dismissed.")
        return self
    }

    @discardableResult
    public func tapAddCustomAmount(amount: String, name: String? = nil) -> Self {
        let customAmountEntryRow = app.buttons["pos-custom-amount-entry-row"]
        customAmountEntryRow.scrollIntoView(app: app)
        XCTAssertTrue(customAmountEntryRow.waitForIsHittable(timeout: 10), "Custom amount entry row should be tappable.")
        customAmountEntryRow.tap()

        let amountField = app.descendants(matching: .any).matching(identifier: "pos-custom-amount-amount-field").firstMatch
        XCTAssertTrue(waitForVisibleElement(amountField, timeout: 10), "Custom amount amount field should be visible.")
        amountField.tap()
        if let firstDigit = amount.first {
            XCTAssertTrue(app.keys[String(firstDigit)].waitForExistence(timeout: 5), "Custom amount keyboard should be visible.")
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.3))
        }
        app.typeText(amount)

        if let name {
            let nameField = app.textFields["pos-custom-amount-name-field"]
            XCTAssertTrue(nameField.waitForExistence(timeout: 10), "Custom amount name field should exist.")
            nameField.scrollIntoView(app: app)
            XCTAssertTrue(nameField.waitForIsHittable(timeout: 10), "Custom amount name field should be tappable.")
            nameField.tap()
            nameField.typeText(name)
        }

        let submitButton = app.buttons["pos-add-custom-amount-submit-button"]
        if submitButton.waitForIsHittable(timeout: 2) {
            submitButton.tap()
        } else {
            XCTAssertTrue(waitForVisibleElement(submitButton, timeout: 5), "Custom amount submit button should be visible.")
            submitButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }

        showPhoneCartIfNeeded()
        XCTAssertTrue(app.descendants(matching: .any)["pos-custom-amount-row"].waitForExistence(timeout: 10),
                      "Custom amount should be visible in the POS cart.")
        return self
    }

    @discardableResult
    public func verifyCartContainsProduct(productID: Int) -> Self {
        showPhoneCartIfNeeded()
        let cartItem = app.descendants(matching: .any)["pos-cart-item-product-\(productID)"]
        XCTAssertTrue(cartItem.waitForExistence(timeout: 10), "Product \(productID) should be visible in the POS cart.")
        return self
    }

    @discardableResult
    public func verifyCartContainsVariation(variationID: Int) -> Self {
        showPhoneCartIfNeeded()
        let cartItem = app.descendants(matching: .any)["pos-cart-item-variation-\(variationID)"]
        XCTAssertTrue(cartItem.waitForExistence(timeout: 10), "Variation \(variationID) should be visible in the POS cart.")
        return self
    }

    @discardableResult
    public func verifyCartItemCount(_ count: Int) -> Self {
        showPhoneCartIfNeeded()
        let itemCountLabel = count == 1 ? "1 item" : "\(count) items"
        XCTAssertTrue(app.staticTexts[itemCountLabel].waitForExistence(timeout: 10), "POS cart should show \(itemCountLabel).")
        return self
    }

    @discardableResult
    public func removeProductFromCart(productID: Int, remainingCartItemCount: Int) -> Self {
        showPhoneCartIfNeeded()
        let cartItem = app.buttons.matching(identifier: "pos-cart-item-product-\(productID)").firstMatch
        cartItem.scrollIntoView(app: app)
        XCTAssertTrue(waitForVisibleElement(cartItem, timeout: 10), "Product \(productID) cart row should be visible.")
        tapTrailingRemoveAffordance(in: cartItem)

        return verifyCartItemCount(remainingCartItemCount)
    }

    @discardableResult
    public func verifyCartContainsCustomAmount(named name: String? = nil) -> Self {
        showPhoneCartIfNeeded()
        let customAmountRow = app.descendants(matching: .any)["pos-custom-amount-row"]
        XCTAssertTrue(customAmountRow.waitForExistence(timeout: 10), "Custom amount row should be visible in the POS cart.")
        if let name {
            XCTAssertTrue(customAmountRow.label.contains(name), "Custom amount name should be visible in the POS cart.")
        }
        return self
    }

    @discardableResult
    public func removeCustomAmountFromCart() -> Self {
        showPhoneCartIfNeeded()
        let customAmountRow = app.descendants(matching: .any).matching(identifier: "pos-custom-amount-row").firstMatch
        XCTAssertTrue(waitForVisibleElement(customAmountRow, timeout: 10), "Custom amount row should be visible.")
        tapTrailingRemoveAffordance(in: customAmountRow)
        customAmountRow.waitForElementToNotExist(element: customAmountRow, timeout: 10)
        return self
    }

    @discardableResult
    public func showPhoneCartIfNeeded() -> Self {
        // Tablet keeps the cart pane visible; phone exposes it through a collapsed cart button.
        let phoneCartButton = app.buttons["pos-phone-cart-button"]
        if waitForVisibleElement(cartViewGetter(app), timeout: 1), !phoneCartButton.isHittable {
            return self
        }

        XCTAssertTrue(phoneCartButton.waitForIsHittable(timeout: 10), "POS cart should be visible or available from the phone cart button.")
        phoneCartButton.tap()
        XCTAssertTrue(waitForVisibleElement(cartViewGetter(app), timeout: 10), "POS cart should be visible after tapping the phone cart button.")
        return self
    }

    @discardableResult
    public func dismissPhoneCartIfNeeded() -> Self {
        let phoneCartButton = app.buttons["pos-phone-cart-button"]
        guard phoneCartButton.exists, waitForVisibleElement(cartViewGetter(app), timeout: 1) else {
            return self
        }

        app.swipeDown()
        XCTAssertTrue(phoneCartButton.waitForIsHittable(timeout: 10), "Phone cart should be dismissed.")
        XCTAssertTrue(firstProductCardGetter(app).waitForExistence(timeout: 10), "POS product list should be visible after dismissing the phone cart.")
        return self
    }

    @discardableResult
    public func tapCheckout() -> Self {
        showPhoneCartIfNeeded()
        let checkoutButton = app.buttons["pos-checkout-button"]

        XCTAssertTrue(checkoutButton.waitForIsHittable(timeout: 15), "POS checkout button should be tappable.")

        checkoutButton.tap()
        return self
    }

    @discardableResult
    public func waitForTotalsLoaded() -> Self {
        // Wait for the actual totals to load (not shimmer/ghost state)
        // This waits for orderState to be .loaded and payment to start
        let totalField = app.descendants(matching: .any)["pos-total-field"]

        XCTAssertTrue(totalField.waitForExistence(timeout: 30), "POS totals should load.")

        return self
    }

    @discardableResult
    public func tapBackToProductSelectorFromCheckout() -> Self {
        let backButton = app.buttons["pos-cart-back-button"]

        XCTAssertTrue(backButton.waitForIsHittable(timeout: 15), "POS cart back button should be tappable from checkout.")

        backButton.tap()
        return self
    }

    @discardableResult
    public func verifyVariationSelectorVisible(variationID: Int) -> Self {
        let variationButton = app.buttons["pos-variation-card-\(variationID)"]

        XCTAssertTrue(waitForVisibleElement(variationButton, timeout: 15), "POS variation selector should remain visible when returning to edit the cart.")

        return self
    }

    @discardableResult
    public func tapCardReaderPayment() -> Self {
        let cardReaderButton = app.buttons["pos-card-reader-button"]
        if cardReaderButton.waitForIsHittable(timeout: 2) {
            cardReaderButton.tap()
            return self
        }

        let otherPaymentMethodsButton = app.buttons["pos-other-payment-methods-button"]
        XCTAssertTrue(
            otherPaymentMethodsButton.waitForIsHittable(timeout: 15),
            "Card reader payment button or Other payment methods button should be tappable."
        )
        otherPaymentMethodsButton.tap()

        let cardReaderSheetRow = app.buttons["pos-other-payments-card-reader"]
        XCTAssertTrue(cardReaderSheetRow.waitForIsHittable(timeout: 15), "Card reader payment option should be tappable in Other payment methods.")

        cardReaderSheetRow.tap()
        return self
    }

    @discardableResult
    public func waitForCardPaymentStartedOrSucceeded() -> Self {
        XCTAssertTrue(waitForCardPaymentPromptOrSuccess(timeout: 90), "Card payment flow should show the reader prompt or reach payment success.")

        return self
    }

    @discardableResult
    public func waitForCardPaymentReady() -> Self {
        // Wait for card payment UI to be ready with "Tap, swipe or insert card" message
        let cardPaymentMessage = app.otherElements["pos-card-payment-message"]

        guard cardPaymentMessage.waitForExistence(timeout: 3) else {
            return self
        }

        return self
    }

    @discardableResult
    public func tapConnectReader() -> Self {
        // Tap the "Connect your reader" button to initiate card reader connection
        let connectButton = app.buttons["pos-connect-reader-button"]

        guard connectButton.waitForExistence(timeout: 3) else {
            return self
        }

        connectButton.tap()
        return self
    }

    @discardableResult
    public func waitForReaderConnected() -> Self {
        // Wait for the reader connection status to show "Reader connected"
        let connectedStatus = app.otherElements["pos-reader-connected"]

        guard connectedStatus.waitForExistence(timeout: 3) else {
            return self
        }

        return self
    }

    @discardableResult
    public func tapCashPayment() -> Self {
        let cashButton = app.buttons["pos-cash-payment-button"]

        XCTAssertTrue(cashButton.waitForIsHittable(timeout: 15), "Cash payment button should be tappable.")

        cashButton.tap()
        return self
    }

    @discardableResult
    public func tapMarkPaymentComplete() -> Self {
        let completeButton = app.buttons["pos-mark-payment-complete-button"]

        XCTAssertTrue(completeButton.waitForIsHittable(timeout: 15), "Mark payment complete button should be tappable.")

        completeButton.tap()
        return self
    }

    @discardableResult
    public func waitForPaymentSuccess() -> Self {
        let successView = app.descendants(matching: .any)["pos-payment-success-view"]

        XCTAssertTrue(successView.waitForExistence(timeout: 30), "POS payment success screen should be visible.")

        return self
    }

    @discardableResult
    public func tapNewOrder() -> Self {
        let newOrderButton = app.buttons["pos-new-order-button"]
        XCTAssertTrue(waitForVisibleElement(newOrderButton, timeout: 15), "New order button should be visible on the payment success screen.")

        if newOrderButton.isHittable {
            newOrderButton.tap()
            return self
        }

        // XCTest can report this animated SwiftUI button as non-hittable even after it is visible.
        newOrderButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        return self
    }

    @discardableResult
    public func verifyReadyForNewOrder(previousProductID: Int? = nil, previousVariationID: Int? = nil) -> Self {
        let phoneCartButton = app.buttons["pos-phone-cart-button"]

        XCTAssertTrue(firstProductCardGetter(app).waitForExistence(timeout: 15), "POS product list should be visible for a new order.")

        if phoneCartButton.waitForIsHittable(timeout: 1) {
            // Phone uses a collapsed cart button; tablet keeps the cart pane visible.
            XCTAssertTrue(phoneCartButton.label.contains("0"), "Phone cart button should show an empty cart for a new order.")
        } else {
            XCTAssertTrue(cartViewGetter(app).waitForExistence(timeout: 10), "POS cart should be visible for a new order.")
            if let previousProductID {
                let previousProductCartItem = app.descendants(matching: .any)["pos-cart-item-product-\(previousProductID)"]
                previousProductCartItem.waitForElementToNotExist(element: previousProductCartItem, timeout: 10)
            }
            if let previousVariationID {
                let previousVariationCartItem = app.descendants(matching: .any)["pos-cart-item-variation-\(previousVariationID)"]
                previousVariationCartItem.waitForElementToNotExist(element: previousVariationCartItem, timeout: 10)
            }
        }
        return self
    }

    @discardableResult
    public func tapMenuButton() -> Self {
        let menuButton = app.buttons["pos-menu-button"]
        if menuButton.waitForIsHittable(timeout: 2) {
            menuButton.tap()
            return self
        }

        let phoneOverflowMenu = app.buttons["pos-phone-overflow-menu"]
        XCTAssertTrue(phoneOverflowMenu.waitForIsHittable(timeout: 10), "POS menu button should be tappable.")
        phoneOverflowMenu.tap()
        return self
    }

    @discardableResult
    public func tapExitMenuItem() -> Self {
        return tapMenuItem(identifier: "pos-exit-menu-item", label: "Exit POS")
    }

    @discardableResult
    public func tapSettingsMenuItem() -> Self {
        return tapMenuItem(identifier: "pos-settings-menu-item", label: "Settings")
    }

    @discardableResult
    public func verifySettingsVisible() -> Self {
        let settingsView = app.descendants(matching: .any)["pos-settings-view"]
        XCTAssertTrue(settingsView.waitForExistence(timeout: 15), "POS settings should be visible.")
        return self
    }

    @discardableResult
    public func dismissSettings() -> Self {
        let settingsTitle = app.staticTexts["Settings"]
        XCTAssertTrue(waitForVisibleElement(settingsTitle, timeout: 10), "POS settings title should be visible.")
        settingsTitle.coordinate(withNormalizedOffset: CGVector(dx: -0.65, dy: 0.5)).tap()
        XCTAssertTrue(firstProductCardGetter(app).waitForExistence(timeout: 15), "POS product list should be visible after dismissing settings.")
        return self
    }

    @discardableResult
    public func confirmExitPOS() throws -> TabNavComponent {
        let exitButton = app.buttons["pos-exit-confirm-button"]

        XCTAssertTrue(exitButton.waitForIsHittable(timeout: 10), "Exit POS confirmation button should be tappable.")

        exitButton.tap()
        return try TabNavComponent()
    }

    private func waitForCardPaymentPromptOrSuccess(timeout: TimeInterval) -> Bool {
        let cardPaymentMessage = app.descendants(matching: .any)["pos-card-payment-message"]
        let successView = app.descendants(matching: .any)["pos-payment-success-view"]
        let connectToReaderButton = app.buttons["Connect to Reader"]
        let locationContinueButton = app.buttons["Continue"]
        let locationRequiredSettingsButton = app.buttons["Open Device Settings"]
        let connectionSuccessDoneButton = app.buttons["Done"]
        let connectionFailedTitle = app.staticTexts["We couldn't connect your reader"]
        let connectionFailedNonRetryableTitle = app.staticTexts["Connection failed"]

        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if cardPaymentMessage.exists || successView.exists {
                return true
            }

            if connectToReaderButton.waitForIsHittable(timeout: 0.2) {
                connectToReaderButton.tap()
            } else if locationContinueButton.waitForIsHittable(timeout: 0.2) {
                locationContinueButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
                handleSystemLocationPermissionIfNeeded()
            } else if connectionSuccessDoneButton.waitForIsHittable(timeout: 0.2) {
                connectionSuccessDoneButton.tap()
            } else if locationRequiredSettingsButton.exists {
                return false
            } else if connectionFailedTitle.exists || connectionFailedNonRetryableTitle.exists {
                return false
            }

            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.2))
        }

        return cardPaymentMessage.exists || successView.exists
    }

    @discardableResult
    private func tapMenuItem(identifier: String, label: String) -> Self {
        let menuItemByIdentifier = app.buttons[identifier]
        if menuItemByIdentifier.waitForIsHittable(timeout: 5) {
            menuItemByIdentifier.tap()
            return self
        }

        let menuItemByLabel = app.buttons[label]
        XCTAssertTrue(menuItemByLabel.waitForIsHittable(timeout: 10), "\(label) menu item should be tappable.")
        menuItemByLabel.tap()
        return self
    }

    private func tapTrailingRemoveAffordance(in row: XCUIElement) {
        // Cart rows expose a stable identifier for the full row, but the small trailing
        // trash button can inherit the row identity in SwiftUI's accessibility tree and
        // is not consistently hittable when queried directly. After confirming the row is
        // visible, tap the trailing edge where the remove affordance is rendered.
        row.coordinate(withNormalizedOffset: CGVector(dx: 0.92, dy: 0.5)).tap()
    }

    private func handleSystemLocationPermissionIfNeeded() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let permissionButtons = [
            springboard.buttons["Allow While Using App"],
            springboard.buttons["Allow Once"]
        ]

        for button in permissionButtons where button.waitForIsHittable(timeout: 1) {
            button.tap()
            return
        }
    }

    private func waitForVisibleElement(_ element: XCUIElement, timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)

        while Date() < deadline {
            if element.exists, element.frame.width > 0, element.frame.height > 0 {
                return true
            }

            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.2))
        }

        return element.exists && element.frame.width > 0 && element.frame.height > 0
    }
}
