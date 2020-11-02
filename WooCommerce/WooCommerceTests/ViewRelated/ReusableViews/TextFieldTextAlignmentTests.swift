import XCTest
@testable import WooCommerce

final class TextFieldTextAlignmentTests: XCTestCase {

    // MARK: .leading

    func test_TextField_text_leading_alignment_maps_to_left_for_LTR() {
        // Arrange
        let textAlignment = TextFieldTextAlignment.leading

        // Action
        let nsTextAlignment = textAlignment.toTextAlignment(layoutDirection: .leftToRight)

        // Assert
        XCTAssertEqual(nsTextAlignment, .left)
    }

    func test_TextField_text_leading_alignment_maps_to_right_for_RTL() {
        // Arrange
        let textAlignment = TextFieldTextAlignment.leading

        // Action
        let nsTextAlignment = textAlignment.toTextAlignment(layoutDirection: .rightToLeft)

        // Assert
        XCTAssertEqual(nsTextAlignment, .right)
    }

    // MARK: .trailing

    func test_TextField_text_trailing_alignment_maps_to_right_for_LTR() {
        // Arrange
        let textAlignment = TextFieldTextAlignment.trailing

        // Action
        let nsTextAlignment = textAlignment.toTextAlignment(layoutDirection: .leftToRight)

        // Assert
        XCTAssertEqual(nsTextAlignment, .right)
    }

    func test_TextField_text_trailing_alignment_maps_to_left_for_RTL() {
        // Arrange
        let textAlignment = TextFieldTextAlignment.trailing

        // Action
        let nsTextAlignment = textAlignment.toTextAlignment(layoutDirection: .rightToLeft)

        // Assert
        XCTAssertEqual(nsTextAlignment, .left)
    }

    // MARK: .center

    func test_TextField_text_center_alignment_maps_to_center_for_LTR() {
        // Arrange
        let textAlignment = TextFieldTextAlignment.center

        // Action
        let nsTextAlignment = textAlignment.toTextAlignment(layoutDirection: .leftToRight)

        // Assert
        XCTAssertEqual(nsTextAlignment, .center)
    }

    func test_TextField_text_center_alignment_maps_to_center_for_RTL() {
        // Arrange
        let textAlignment = TextFieldTextAlignment.center

        // Action
        let nsTextAlignment = textAlignment.toTextAlignment(layoutDirection: .rightToLeft)

        // Assert
        XCTAssertEqual(nsTextAlignment, .center)
    }
}
