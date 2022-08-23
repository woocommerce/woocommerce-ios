import ScreenObject
import XCTest

public final class MenuScreen: ScreenObject {
    static var isVisible: Bool {
        (try? MenuScreen().isLoaded) ?? false
    }

    private let reviewsButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["menu-reviews"]
    }

    private let viewStoreButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["menu-view-store"]
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

    public init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [
                reviewsButtonGetter,
                viewStoreButtonGetter
            ],
            app: app
        )
    }

    @discardableResult
    public func goToReviewsScreen() throws -> ReviewsScreen {
        reviewsButton.tap()
        return try ReviewsScreen()
    }

    @discardableResult
    public func openSettingsPane() throws -> SettingsScreen {
        app.buttons["dashboard-settings-button"].tap()
        return try SettingsScreen()
    }

    @discardableResult
    public func verifySelectedStoreDisplays(storeTitle expectedStoreTitle: String, storeURL expectedStoreUrl: String) -> MenuScreen {
        let actualStoreTitle = selectedStoreTitleGetter(app).label
        let actualStoreUrl = selectedStoreUrlGetter(app).label

        XCTAssertEqual(expectedStoreTitle, actualStoreTitle,
                       "Expected display name '\(expectedStoreTitle)' but '\(actualStoreTitle)' was displayed instead.")
        XCTAssertEqual(expectedStoreUrl, actualStoreUrl,
                       "Expected site URL \(expectedStoreUrl) but \(actualStoreUrl) was displayed instead.")
        return self
    }
}
