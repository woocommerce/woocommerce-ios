
import XCTest
import UIKit

@testable import WooCommerce

/// Tests for methods in NSMutableAttributedString+Helpers
///
final class NSMutableAttributedStringHelperTests: XCTestCase {

    func testReplaceFirstOccurrenceReplacesTheFirstMatch() {
        // Arrange
        let attributedString = NSMutableAttributedString(string: "Will the real #{person} please stand up?")
        let replacement = NSAttributedString(string: "Slim Shady",
                                             attributes: [.font: UIFont.boldSystemFont(ofSize: 32)])

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

    func testWhenReplacementExistsInTheStringReplaceFirstOccurrenceCorrectlyReplacesTheTarget() {
        // Arrange
        let repeatedWord = "_echo_"
        // The attributedString also contains the repeatedWord
        let format = "_echo__echo_%@_echo__echo_"

        let rangeUpToPlaceholder = NSRange(format.startIndex..<format.range(of: "%@")!.lowerBound, in: format)

        let attributedString = NSMutableAttributedString(string: format)
        let replacement = NSAttributedString(string: repeatedWord,
                                             attributes: [.font: UIFont.italicSystemFont(ofSize: 64)])

        // Act
        attributedString.replaceFirstOccurrence(of: "%@", with: replacement)

        // Assert
        // The placeholder %@ is still replaced with the defined "_echo_" replacement
        XCTAssertEqual(attributedString.string, "_echo__echo__echo__echo__echo_")

        // Assert that there are no attributes (e.g. bold) from the first character to the
        // beginning of the replaced placeholder ("%@").
        var effectiveRange = NSRange()
        let attributesBeforePlaceholder = attributedString.attributes(at: 0, effectiveRange: &effectiveRange)
        XCTAssertTrue(attributesBeforePlaceholder.isEmpty)
        XCTAssertEqual(effectiveRange, rangeUpToPlaceholder)

        // Assert that the italic font attribute is applied to the inserted "_echo_"
        let attributesAtPlaceholder = attributedString.attributes(at: rangeUpToPlaceholder.upperBound,
                                                                  effectiveRange: &effectiveRange)
        XCTAssertFalse(attributesAtPlaceholder.isEmpty)
        XCTAssertEqual(effectiveRange, NSMakeRange(rangeUpToPlaceholder.upperBound, repeatedWord.characterCount))
        // Assert that it's the italic font that we defined earlier
        let font = attributesAtPlaceholder[.font] as! UIFont
        XCTAssertTrue(font.fontDescriptor.symbolicTraits.contains(.traitItalic))
        XCTAssertEqual(font.pointSize, 64)
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
