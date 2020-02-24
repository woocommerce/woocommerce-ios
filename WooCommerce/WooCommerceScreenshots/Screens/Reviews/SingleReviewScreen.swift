import Foundation
import XCTest

class SingleReviewScreen: BaseScreen {

    struct ElementStringIDs {
        static let spamButton = "single-review-spam-button"
        static let trashButton = "single-review-trash-button"
        static let approveButton = "single-review-approval-button"
    }

    let tabBar = TabNavComponent()
    let spamButton = XCUIApplication().buttons[ElementStringIDs.spamButton]
    let trashButton = XCUIApplication().buttons[ElementStringIDs.trashButton]
    let approveButton = XCUIApplication().buttons[ElementStringIDs.approveButton]

    static var isVisible: Bool {
        let spamButton = XCUIApplication().buttons[ElementStringIDs.spamButton]
        return spamButton.exists && spamButton.isHittable
    }

    init() {
        super.init(element: spamButton)

        XCTAssert(spamButton.waitForExistence(timeout: 3))
        XCTAssert(trashButton.waitForExistence(timeout: 3))
        XCTAssert(approveButton.waitForExistence(timeout: 3))
    }

    @discardableResult
    func goBackToReviewsScreen() -> ReviewsScreen {
        pop()
        return ReviewsScreen()
    }
}
