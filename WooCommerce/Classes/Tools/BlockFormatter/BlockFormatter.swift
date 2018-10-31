import Foundation
import Networking


/// BlockFormatter: Returns an AttributedString with all of the Block's Ranges metadata formatted with the specified Styles.
///
struct BlockFormatter {

    /// Returns An AttributedString representation of the received Block, with a specific collection of Styles applied.
    ///
    func format(block: NoteBlock, with styles: BlockFormatterStyles) -> NSAttributedString {
        guard let text = block.text else {
            return NSAttributedString()
        }

        let tightenedText = replaceCommonWhitespaceIssues(in: text)
        let output = NSMutableAttributedString(string: tightenedText, attributes: styles.regular)

        if let quoteStyle = styles.italics ?? styles.bold {
            output.applyAttributesToQuotedText(attributes: quoteStyle)
        }

        // Apply the Ranges
        var lengthShift = 0

        for range in block.ranges {
            var shiftedRange        = range.range
            shiftedRange.location   += lengthShift

            if range.kind == .noticon {
                let noticon         = (range.value ?? String()) + " "
                output.replaceCharacters(in: shiftedRange, with: noticon)
                lengthShift         += noticon.count
                shiftedRange.length += noticon.count
            }

            if let rangeStyle = styles.attributes(for: range.kind) {
                output.addAttributes(rangeStyle, range: shiftedRange)
            }

            if let rangeURL = range.url, let linksColor = styles.linkColor {
                output.addAttribute(.link, value: rangeURL, range: shiftedRange)
                output.addAttribute(.foregroundColor, value: linksColor, range: shiftedRange)
            }
        }

        return output
    }

    /// Replaces some common extra whitespace with hairline spaces so that comments display better
    ///
    /// - Parameter baseString: string of the comment body before attributes are added
    /// - Returns: string of same length
    /// - Note: the length must be maintained or the formatting will break
    ///
    private func replaceCommonWhitespaceIssues(in baseString: String) -> String {
        /// \u{200A} = hairline space (very skinny space).
        /// we use these so that the ranges are still in the right position, but the extra space basically disappears
        ///
        let output = baseString
            .replacingOccurrences(of: "\t ", with: "\u{200A}\u{200A}") // tabs before a space
            .replacingOccurrences(of: " \t", with: " \u{200A}") // tabs after a space
            .replacingOccurrences(of: "\t@", with: "\u{200A}@") // tabs before @mentions
            .replacingOccurrences(of: "\t.", with: "\u{200A}.") // tabs before a space
            .replacingOccurrences(of: "\t,", with: "\u{200A},") // tabs cefore a comman
            .replacingOccurrences(of: "\n\t\n\t", with: "\u{200A}\u{200A}\n\t") // extra newline-with-tab before a newline-with-tab

        // if the length of the string changes the range-based formatting will break
        guard output.count == baseString.count else {
            return baseString
        }

        return output
    }
}
