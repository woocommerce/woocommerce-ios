
import XCTest
import UIKit

@testable import WooCommerce

/// Tests for methods in NSMutableAttributedString+Helpers
///
final class NSMutableAttributedStringHelperTests: XCTestCase {

    func testReplaceFirstOccurrenceReplacesTheFirstMatch() {
        // Arrange
        let attributedString = NSMutableAttributedString(string: "Will the real #{person} please stand up?")
        let replacement = NSAttributedString(string: "Slim Shady", attributes: [.font: UIFont.boldSystemFont(ofSize: 32)])

        // Act
        attributedString.replaceFirstOccurrence(of: "#{person}", with: replacement)

        // Assert
        XCTAssertEqual(attributedString.string, "Will the real Slim Shady please stand up?")
        // There are no attributes at the first character
        XCTAssertTrue(attributedString.attributes(at: 0, effectiveRange: nil).isEmpty)

        // There is an attribute at 14 (the position of "#{person}") which was replaced.
        let attributes = attributedString.attributes(at: 14, effectiveRange: nil)
        XCTAssertFalse(attributes.isEmpty)

        let font = attributes[.font] as! UIFont
        XCTAssertTrue(font.fontDescriptor.symbolicTraits.contains(.traitBold))
        XCTAssertEqual(font.pointSize, 32)
    }

    func testReplaceFirstOccurrenceOnlyReplacesTheFirstMatch() {
        // Arrange
        let attributedString = NSMutableAttributedString(string: "Hi {name}. How are you, {name}?")
        let replacement = NSAttributedString(string: "Wilmer")

        // Act
        attributedString.replaceFirstOccurrence(of: "{name}", with: replacement)

        // Assert
        XCTAssertEqual(attributedString.string, "Hi Wilmer. How are you, {name}?")
    }

    func testReplaceFirstOccurrenceFinishesSafelyIfTheTargetIsNotFound() {
        // Arrange
        let attributedString = NSMutableAttributedString(string: "These are the days of our lives")
        let replacement = NSAttributedString(string: "Wilmer")

        // Act
        attributedString.replaceFirstOccurrence(of: "{name}", with: replacement)

        // Assert
        // Nothing changed
        XCTAssertEqual(attributedString.string, "These are the days of our lives")
    }
}
