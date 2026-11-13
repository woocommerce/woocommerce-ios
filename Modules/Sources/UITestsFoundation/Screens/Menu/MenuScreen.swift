import ScreenObject
import XCTest

@MainActor
public final class MenuScreen: ScreenObject {
    static var isVisible: Bool {
        (try? MenuScreen().isLoaded) ?? false
    }

    private let reviewsButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["menu-reviews"]
    }

    private let paymentsButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["menu-payments"]
    }

    private let selectedStoreTitleGetter: (XCUIApplication) -> XCUIElement = {
        $0.staticTexts["store-title"]
    }

    private let selectedStoreUrlGetter: (XCUIApplication) -> XCUIElement = {
        $0.staticTexts["store-url"]
    }

    /// Button to open the Reviews section
    ///
    private var reviewsButton: XCUIElement { reviewsButtonGetter(app) }
    private var paymentsButton: XCUIElement { paymentsButtonGetter(app) }

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [
                selectedStoreTitleGetter
            ],
            app: app
        )
    }

    @discardableResult
    public func goToReviewsScreen() throws -> ReviewsScreen {
        scrollToRow(reviewsButton)
        reviewsButton.tap()
        return try ReviewsScreen()
    }

    @discardableResult
    public func goToPaymentsScreen() throws -> PaymentsScreen {
        scrollToRow(paymentsButton)
        paymentsButton.tap()
        return try PaymentsScreen()
    }

    private func scrollToRow(_ row: XCUIElement) {
        let window = app.windows.firstMatch
        for _ in 0..<10 {
            let tabBar = app.tabBars.firstMatch
            let visibleFrame = window.frame
            if row.exists && row.isHittable && visibleFrame.contains(row.frame)
                && !(tabBar.exists && row.frame.intersects(tabBar.frame)) {
                return
            }
            let scrollUp = !row.exists || row.frame.midY > visibleFrame.midY
            let start = window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: scrollUp ? 0.7 : 0.3))
            let end = window.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: scrollUp ? 0.3 : 0.7))
            start.press(forDuration: 0.05, thenDragTo: end, withVelocity: .slow, thenHoldForDuration: 0.1)
        }
        XCTFail("Menu row is not visible: \(row.identifier)")
    }

    @discardableResult
    public func openSettingsPane() throws -> SettingsScreen {
        app.buttons["dashboard-settings-button"].tap()
        return try SettingsScreen()
    }

    @discardableResult
    public func verifySelectedStoreDisplays(storeTitle expectedStoreTitle: String, storeURL expectedStoreUrl: String) -> Self {
        let actualStoreTitle = selectedStoreTitleGetter(app).label
        let actualStoreUrl = selectedStoreUrlGetter(app).label

        XCTAssertEqual(expectedStoreTitle, actualStoreTitle)
        XCTAssertEqual(expectedStoreUrl, actualStoreUrl)
        return self
    }
}
