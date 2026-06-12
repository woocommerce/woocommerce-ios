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
        if phoneCartButton.waitForIsHittable(timeout: 1) {
            // Phone uses a collapsed cart button; tablet keeps the cart pane visible.
            XCTAssertTrue(firstProductCardGetter(app).waitForExistence(timeout: 15), "POS product list should be visible for a new order.")
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

        guard menuButton.waitForExistence(timeout: 3) else {
            return self
        }

        menuButton.tap()
        return self
    }

    @discardableResult
    public func tapExitMenuItem() -> Self {
        let exitMenuItem = app.buttons["pos-exit-menu-item"]

        guard exitMenuItem.waitForExistence(timeout: 3) else {
            return self
        }

        exitMenuItem.tap()
        return self
    }

    @discardableResult
    public func confirmExitPOS() throws -> TabNavComponent {
        let exitButton = app.buttons["pos-exit-confirm-button"]

        guard exitButton.waitForExistence(timeout: 3) else {
            return try TabNavComponent()
        }

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
