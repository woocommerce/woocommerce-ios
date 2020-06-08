import Foundation


/// NSMutableAttributedString: Helper Methods
///
extension NSMutableAttributedString {

    /// Applies the specified attributes to the receiver's quoted text.
    ///
    func applyAttributesToQuotedText( attributes: [NSAttributedString.Key: Any]) {
        let scanner = Scanner(string: string)
        for range in scanner.scanQuotedRanges() {
            addAttributes(attributes, range: range)
        }
    }

    /// Replaces the first found occurrence of `target` with the `replacement`.
    ///
    /// Example usage:
    ///
    /// ```
    /// let attributedString = NSMutableAttributedString(string: "Hello, #{person}")
    /// let replacement = NSAttributedString(string: "Slim Shady",
    ///                                      attributes: [.font: UIFont.boldSystemFont(ofSize: 32)])
    /// attributedString.replaceFirstOccurrence(of: "#{person}", with: replacement)
    /// ```
    ///
    func replaceFirstOccurrence(of target: String, with replacement: NSAttributedString) {
        guard let range = string.range(of: target) else {
            return
        }
        let nsRange = NSRange(range, in: string)

        replaceCharacters(in: nsRange, with: replacement)
    }
}
