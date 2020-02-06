import Foundation


/// String: HTML Stripping
///
extension String {

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
