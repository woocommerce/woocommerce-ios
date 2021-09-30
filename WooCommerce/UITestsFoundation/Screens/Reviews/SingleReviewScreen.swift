import XCTest

public final class SingleReviewScreen: BaseScreen {

    struct ElementStringIDs {
        static let spamButton = "single-review-spam-button"
        static let trashButton = "single-review-trash-button"
        static let approveButton = "single-review-approval-button"
    }

    private let spamButton = XCUIApplication().buttons[ElementStringIDs.spamButton]
    private let trashButton = XCUIApplication().buttons[ElementStringIDs.trashButton]
    private let approveButton = XCUIApplication().buttons[ElementStringIDs.approveButton]

    init() {
        super.init(element: spamButton)

        XCTAssert(spamButton.waitForExistence(timeout: 3))
        XCTAssert(trashButton.waitForExistence(timeout: 3))
        XCTAssert(approveButton.waitForExistence(timeout: 3))
    }

    @discardableResult
    public func goBackToReviewsScreen() throws -> ReviewsScreen {
        pop()
        return try ReviewsScreen()
    }
}
