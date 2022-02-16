import Foundation

extension NSAttributedString {
    /// Returns an `NSAttributedString` with attributes applied to the whole string.
    func addingAttributes(_ attributes: [NSAttributedString.Key: Any]) -> NSAttributedString {
        let attributedHTMLString = NSMutableAttributedString(attributedString: self)

        let range = NSRange(location: 0, length: attributedHTMLString.length)
        attributedHTMLString.addAttributes(attributes, range: range)
        return attributedHTMLString
    }
}
