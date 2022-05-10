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
}
