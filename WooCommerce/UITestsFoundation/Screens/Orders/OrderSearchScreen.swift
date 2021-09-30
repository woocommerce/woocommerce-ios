import ScreenObject
import XCTest

public final class OrderSearchScreen: ScreenObject {

    struct ElementStringIDs {
        static let searchField = "order-search-screen-search-field"
        static let cancelButton = "order-search-screen-cancel-button"
    }

    private let cancelButtonGetter: (XCUIApplication) -> XCUIElement = {
        $0.buttons["order-search-screen-cancel-button"]
    }

    private var cancelButton: XCUIElement { cancelButtonGetter(app) }

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [
                cancelButtonGetter,
                // swiftlint:disable:next opening_braces
                { $0.otherElements["order-search-screen-search-field"] }
            ],
            app: app
        )
    }

    @discardableResult
    public func cancel() throws -> OrdersScreen {
        cancelButton.tap()
        return try OrdersScreen()
    }
}
