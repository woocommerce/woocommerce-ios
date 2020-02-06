import Foundation


/// String: HTML Stripping
///
extension String {

    /// Returns the HTML Stripped version of the receiver.
    ///
    /// NOTE: I can be very slow ⏳ — using it in a background thread is strongly recommended.
    ///
    public var strippedHTML: String {
        guard let data = data(using: .utf8) else {
            return self
        }

        let options: [NSAttributedString.DocumentReadingOptionKey: Any] = [
            .documentType: NSAttributedString.DocumentType.html,
            .characterEncoding: String.Encoding.utf8.rawValue
        ]

        guard let attributedString = try? NSAttributedString(data: data, options: options, documentAttributes: nil) else {
            return self
        }

        return attributedString.string
    }
}
