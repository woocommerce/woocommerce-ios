import Testing
import WooFoundation

struct BidirectionalTextTests {
    @Test func isolateLeftToRightNumericRuns_when_input_contains_arabic_decimal_separator_then_wraps_single_numeric_run() {
        // Given
        let separators = BidirectionalText.numericSeparators(including: ["\u{066B}"])

        // When
        let result = BidirectionalText.isolateLeftToRightNumericRuns(in: "12\u{066B}5%", separators: separators)

        // Then
        #expect(result == "\(BidirectionalText.leftToRightIsolate)12\u{066B}5\(BidirectionalText.popDirectionalIsolate)%")
    }

    @Test func isolateLeftToRightNumericRuns_when_input_ends_with_decimal_separator_then_keeps_separator_in_numeric_run() {
        // When
        let result = BidirectionalText.isolateLeftToRightNumericRuns(in: "$20.")

        // Then
        #expect(result == "$\(BidirectionalText.leftToRightIsolate)20.\(BidirectionalText.popDirectionalIsolate)")
    }

    @Test func isolateLeftToRightNumericRuns_when_input_already_contains_directional_controls_then_returns_input_unchanged() {
        // Given
        let formattedAmount = BidirectionalText.rightToLeftMark +
            BidirectionalText.isolateLeftToRight("-20.00") +
            "\u{0631}.\u{0642}"

        // When
        let result = BidirectionalText.isolateLeftToRightNumericRuns(in: formattedAmount)

        // Then
        #expect(result == formattedAmount)
    }
}
