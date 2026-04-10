import ScreenObject
import XCTest
// periphery: ignore - used for UI testing
public final class POSScreen: ScreenObject {
    private let cartViewGetter: (XCUIApplication) -> XCUIElement = {
        $0.otherElements["pos-cart-view"]
    }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [cartViewGetter],
            app: app
        )
    }

    @discardableResult
    public func tapAddProduct(productID: Int) -> Self {
        let productButton = app.buttons["pos-product-card-\(productID)"]

        guard productButton.waitForExistence(timeout: 1) else {
            return self
        }
        productButton.tap()

        return self
    }

    @discardableResult
    public func tapCheckout() -> Self {
        let checkoutButton = app.buttons["pos-checkout-button"]

        guard checkoutButton.waitForExistence(timeout: 1) else {
            return self
        }

        checkoutButton.tap()
        return self
    }

    @discardableResult
    public func waitForTotalsLoaded() -> Self {
        // Wait for the actual totals to load (not shimmer/ghost state)
        // This waits for orderState to be .loaded and payment to start
        let totalField = app.otherElements["pos-total-field"]

        guard totalField.waitForExistence(timeout: 3) else {
            return self
        }

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

        guard cashButton.waitForExistence(timeout: 3) else {
            return self
        }

        cashButton.tap()
        return self
    }

    @discardableResult
    public func tapMarkPaymentComplete() -> Self {
        let completeButton = app.buttons["pos-mark-payment-complete-button"]

        guard completeButton.waitForExistence(timeout: 3) else {
            return self
        }

        completeButton.tap()
        return self
    }

    @discardableResult
    public func waitForPaymentSuccess() -> Self {
        let successView = app.otherElements["pos-payment-success-view"]

        guard successView.waitForExistence(timeout: 3) else {
            return self
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
}
