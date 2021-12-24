import ScreenObject
import XCTest

public final class SingleReviewScreen: ScreenObject {

    init(app: XCUIApplication = XCUIApplication()) throws {
        try super.init(
            expectedElementGetters: [
                // swiftlint:disable opening_brace
                { $0.buttons["single-review-spam-button"] },
                { $0.buttons["single-review-trash-button"] },
                { $0.buttons["single-review-approval-button"] }
                // swiftlint:enable opening_brace
            ],
            app: app
        )
    }

    @discardableResult
    public func goBackToReviewsScreen() throws -> ReviewsScreen {
        pop()
        return try ReviewsScreen()
    }
}
