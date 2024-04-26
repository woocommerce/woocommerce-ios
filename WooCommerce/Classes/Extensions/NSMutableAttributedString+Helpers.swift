import Foundation
import UIKit


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

    /// Sets a link to a substring in an attributed string.
    ///
    @discardableResult
    func setAsLink(textToFind: String, linkURL: String) -> Bool {
        let foundRange = mutableString.range(of: textToFind)
        if foundRange.location != NSNotFound {
            addAttribute(.link, value: linkURL, range: foundRange)
            return true
        }
        return false
    }

    /// Underlines the given substring (case insensitive). It does nothing if the given substring cannot be found in the original string.
    ///
    func underlineSubstring(underlinedText: String) {
        let range = (string as NSString).range(of: underlinedText, options: .caseInsensitive)
        if range.location != NSNotFound {
            addAttribute(.underlineStyle,
                               value: NSUnderlineStyle.single.rawValue,
                               range: range)
        }

    }

    /// Highlight the given substring (case insensitive). It does nothing if the given substring cannot be found in the original string.
    ///
    func highlightSubstring(textToFind: String, with color: UIColor = .accent) {
        let range = mutableString.range(of: textToFind, options: .caseInsensitive)
        if range.location != NSNotFound {
            addAttribute(.foregroundColor,
                         value: color.cgColor,
                         range: range)
        }
    }
}
