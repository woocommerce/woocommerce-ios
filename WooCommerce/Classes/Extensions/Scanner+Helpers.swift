import Foundation


/// Scanner: Helper Methods
///
extension Scanner {

    /// Returns the NSRange(s) for all of the quotes contained within the scanned string.
    ///
    func scanQuotedRanges() -> [NSRange] {
        var output = [NSRange]()
        let marker = "\""

        while isAtEnd == false {
            // Find + Drop the first quotation mark
            _ = scanUpToString(marker)
            _ = scanString(marker)

            // Scan the actual quoted text
            let start = currentIndex
            _ = scanUpToString(marker)
            let end = currentIndex

            // Drop the closing mark
            _ = scanString(marker)

            // Build the Range
            guard start.utf16Offset(in: self.string) >= 0 && end.utf16Offset(in: self.string) < string.count && start < end else {
                continue
            }

            let foundationRange = NSRange(location: start.utf16Offset(in: self.string),
                                          length: end.utf16Offset(in: self.string) - start.utf16Offset(in: self.string))
            output.append(foundationRange)
        }

        return output
    }
}
