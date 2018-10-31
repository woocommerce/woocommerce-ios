import XCTest
@testable import WooCommerce


/// Scanner+Woo Unit Tests
///
class ScannerWooTests: XCTestCase {

    /// Sample: Empty String
    ///
    private let sampleEmptyText = String()

    /// Sample: Unclosed Quote
    ///
    private let sampleUnclosedQuote = "hello \"i'm a sample snippet with no closing mark"

    /// Sample: Properly Quoted Text / No surroundings
    ///
    private let sampleClosedQuoteWithNoSurroundingText = "\"i'm a proper snippet\""

    /// Sample: Properly Quoted Text / Surrounding Text
    ///
    private let sampleClosedQuoteSurroundedByText = "hello \"i'm a proper snippet\" text"

    /// Sample: Multiple Quoted Strings
    ///
    private let sampleMultipleQuotedText = "hello \"i'm a proper snippet\" text, \"i'm a proper snippet\", \"i'm a proper snippet\""

    /// Sample: Multiple Quoted Strings. Last one unproperly closed
    ///
    private let sampleMultipleQuotedTextWithUnclosedFinalQuote = "hello \"i'm a proper snippet\" text, \"i'm a proper snippet\", \"i'm a broken snippet"

    /// Expected Quoted Text
    ///
    private let expectedQuotedText = "i'm a proper snippet"


    /// Verifies that Empty Strings produce no trouble.
    ///
    func testEmptyStringsYieldNoResults() {
        let scanner = Scanner(string: sampleEmptyText)
        let output = scanner.scanQuotedRanges()
        XCTAssertTrue(output.isEmpty)
    }

    /// Verifies that an unclosed quote is not picked up by the scanner.
    ///
    func testTextWithNoClosingQuoteDoesNotGetPickedUp() {
        let scanner = Scanner(string: sampleUnclosedQuote)
        let output = scanner.scanQuotedRanges()
        XCTAssertTrue(output.isEmpty)
    }

    /// Verifies that a quote with no surrounding text is properly picked up.
    ///
    func testSampleQuotedTextWithNoSurroundingTextYieldsQuotedTextRanges() {
        let scanner = Scanner(string: sampleClosedQuoteWithNoSurroundingText)
        let output = scanner.scanQuotedRanges()
        XCTAssertEqual(output.count, 1)

        let quotedText = (sampleClosedQuoteWithNoSurroundingText as NSString).substring(with: output[0])
        XCTAssertEqual(quotedText, expectedQuotedText)
    }

    /// Verifies that properly quoted substrings are picked up correctly.
    ///
    func testSampleQuotedTextWithSurroundingTextYieldsQuotedTextRanges() {
        let scanner = Scanner(string: sampleClosedQuoteSurroundedByText)
        let output = scanner.scanQuotedRanges()
        XCTAssertEqual(output.count, 1)

        for range in output {
            let quotedText = (sampleClosedQuoteSurroundedByText as NSString).substring(with: range)
            XCTAssertEqual(quotedText, expectedQuotedText)
        }
    }

    /// Verifies that properly quoted substrings are picked up correctly.
    ///
    func testTextWithMultipleQuotesIsProperlyPickedUp() {
        let scanner = Scanner(string: sampleMultipleQuotedTextWithUnclosedFinalQuote)
        let output = scanner.scanQuotedRanges()
        XCTAssertEqual(output.count, 2)

        for range in output {
            let quotedText = (sampleMultipleQuotedTextWithUnclosedFinalQuote as NSString).substring(with: range)
            XCTAssertEqual(quotedText, expectedQuotedText)
        }
    }
}
