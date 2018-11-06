import XCTest
@testable import WooCommerce


/// NSAttributedString+Helper Unit Tests
///
class NSAttributedStringHelperTests: XCTestCase {

    /// Sample Input: Random leading + trailing newlines
    ///
    private let sampleInput = "\n\nSomething\n HERE\n\n"

    /// Expected trimmed string
    ///
    private let expectedOutput = "Something\n HERE"


    /// Verifies that the receiver gets its leading + trailing newlines trimmed.
    ///
    func testTrimNewLinesEffectivelyNukesLeadingAndTrailingLines() {
        let input = NSAttributedString(string: sampleInput)
        let output = input.trimNewlines()

        XCTAssertEqual(output.string, expectedOutput)
    }
}
