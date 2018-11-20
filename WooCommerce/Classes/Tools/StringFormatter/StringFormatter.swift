import Foundation


/// StringFormatter: Helper tool that allows us to format an Input String, based on the associated Descriptors.
///
struct StringFormatter {

    /// Returns An AttributedString representation of the received String, with a specific collection of Styles applied,
    /// according to a given collection of Descriptors.
    ///
    func format(text: String, with styles: StringStyles, using descriptors: [StringDescriptor]) -> NSAttributedString {
        let tightenedText = replaceCommonWhitespaceIssues(in: text)
        let output = NSMutableAttributedString(string: tightenedText, attributes: styles.regular)

        // Style: Quotes
        if let quoteStyle = styles.italics ?? styles.bold {
            output.applyAttributesToQuotedText(attributes: quoteStyle)
        }

        // Style: [Descriptors]
        var lengthShift = 0

        for descriptor in descriptors {
            var shiftedRange        = descriptor.range
            shiftedRange.location   += lengthShift

            // Apply Values
            if let rangeValue = descriptor.value {
                let replacement     = rangeValue + " "
                output.replaceCharacters(in: shiftedRange, with: replacement)
                lengthShift         += replacement.count
                shiftedRange.length += replacement.count
            }

            // Apply Attributes
            if let rangeStyle = descriptor.attributes(from: styles) {
                output.addAttributes(rangeStyle, range: shiftedRange)
            }

            // Apply Links
            if let rangeURL = descriptor.url, let linkStyle = styles.link {
                output.addAttribute(.link, value: rangeURL, range: shiftedRange)
                output.addAttributes(linkStyle, range: shiftedRange)
            }
        }

        return output
    }
}


// MARK: - Private
//
private extension StringFormatter {

    /// Replaces some common extra whitespace with hairline spaces so that comments display better
    ///
    /// - Parameter baseString: string of the comment body before attributes are added
    /// - Returns: string of same length
    /// - Note: the length must be maintained or the formatting will break
    ///
    func replaceCommonWhitespaceIssues(in baseString: String) -> String {
        /// \u{200A} = hairline space (very skinny space).
        /// we use these so that the ranges are still in the right position, but the extra space basically disappears
        ///
        let output = baseString
            .replacingOccurrences(of: "\t ", with: String.hairSpace + String.hairSpace)
            .replacingOccurrences(of: " \t", with: String.space + String.hairSpace)
            .replacingOccurrences(of: "\t@", with: String.hairSpace + "@")
            .replacingOccurrences(of: "\t.", with: String.hairSpace + ".")
            .replacingOccurrences(of: "\t,", with: String.hairSpace + ",")
            .replacingOccurrences(of: "\n\t\n\t", with: String.hairSpace + String.hairSpace + "\n\t")

        // Failsafe: If the length of the string changes the range-based formatting will break
        guard output.count == baseString.count else {
            return baseString
        }

        return output
    }
}
