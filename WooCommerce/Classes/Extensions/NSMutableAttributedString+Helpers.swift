import Foundation

/// NSMutableAttributedString: Helper Methods
///
extension NSMutableAttributedString {

    /// Applies the specified attributes to the receiver's quoted text.
    ///
    func applyAttributesToQuotedText(attributes: [NSAttributedString.Key: Any]) {
        let scanner = Scanner(string: string)
        for range in scanner.scanQuotedRanges() {
            addAttributes(attributes, range: range)
        }
    }
}
