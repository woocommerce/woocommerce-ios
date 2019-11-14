import Foundation


/// String: HTML Stripping
///
extension String {

    /// Returns the HTML Stripped version of the receiver.
    ///
    /// NOTE: I can be very slow ⏳ — please be careful when using me (i.e. tableview cells are probably a bad idea).
    ///
    var strippedHTML: String {
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

    /// Convert HTML to an attributed string
    ///
    var htmlToAttributedString: NSAttributedString {
        guard let data = data(using: .utf8) else { return NSAttributedString() }
        do {
            return try NSAttributedString(data: data,
                                          options: [.documentType: NSAttributedString.DocumentType.html,
                                                    .characterEncoding: String.Encoding.utf8.rawValue],
                                          documentAttributes: nil)
        } catch {
            DDLogError("Error: unable to convert HTML data to an attributed string")
            return NSAttributedString()
        }
    }

    /// Removed all tags in the form of `<*>`.
    ///
    var removedHTMLTags: String {
        let string = replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
        return string
    }
}
