import XCTest
@testable import WooCommerce

final class TextFieldTextAlignmentTests: XCTestCase {

    // MARK: .leading

    func testTextFieldTextLeadingAlignmentMapsToLeftForLTR() {
        // Arrange
        let textAlignment = TextFieldTextAlignment.leading

        // Action
        let nsTextAlignment = textAlignment.toTextAlignment(layoutDirection: .leftToRight)

        // Assert
        XCTAssertEqual(nsTextAlignment, .left)
    }

    func testTextFieldTextLeadingAlignmentMapsToRightForRTL() {
        // Arrange
        let textAlignment = TextFieldTextAlignment.leading

        // Action
        let nsTextAlignment = textAlignment.toTextAlignment(layoutDirection: .rightToLeft)

        // Assert
        XCTAssertEqual(nsTextAlignment, .right)
    }

    // MARK: .trailing

    func testTextFieldTextTrailingAlignmentMapsToRightForLTR() {
        // Arrange
        let textAlignment = TextFieldTextAlignment.trailing

        // Action
        let nsTextAlignment = textAlignment.toTextAlignment(layoutDirection: .leftToRight)

        // Assert
        XCTAssertEqual(nsTextAlignment, .right)
    }

    func testTextFieldTextTrailingAlignmentMapsToLeftForRTL() {
        // Arrange
        let textAlignment = TextFieldTextAlignment.trailing

        // Action
        let nsTextAlignment = textAlignment.toTextAlignment(layoutDirection: .rightToLeft)

        // Assert
        XCTAssertEqual(nsTextAlignment, .left)
    }

    // MARK: .center

    func testTextFieldTextCenterAlignmentMapsToCenterForLTR() {
        // Arrange
        let textAlignment = TextFieldTextAlignment.center

        // Action
        let nsTextAlignment = textAlignment.toTextAlignment(layoutDirection: .leftToRight)

        // Assert
        XCTAssertEqual(nsTextAlignment, .center)
    }

    func testTextFieldTextCenterAlignmentMapsToCenterForRTL() {
        // Arrange
        let textAlignment = TextFieldTextAlignment.center

        // Action
        let nsTextAlignment = textAlignment.toTextAlignment(layoutDirection: .rightToLeft)

        // Assert
        XCTAssertEqual(nsTextAlignment, .center)
    }
}
