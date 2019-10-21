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
            scanUpTo(marker, into: nil)
            scanString(marker, into: nil)

            // Scan the actual quoted text
            let start = scanLocation
            scanUpTo(marker, into: nil)
            let end = scanLocation

            // Drop the closing mark
            scanString(marker, into: nil)

            // Build the Range
            guard start >= 0 && end < string.count && start < end else {
                continue
            }

            let foundationRange = NSRange(location: start, length: end - start)
            output.append(foundationRange)
        }

        return output
    }
}
