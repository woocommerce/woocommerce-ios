import Foundation


/// String: HTML Stripping
///
extension String {

    /// Convert HTML to an attributed string
    ///
    /// This method uses `NSAttributedString.init(data:options:documentAttributes:)` with a documentType value of html.
    /// Internally it uses WebKit so it should only be called from the main thread.
    ///
    /// Even then, the implementation seems to suspend the execution while WebKit is loading and might continue processing other events in the run loop.
    ///
    /// See [#4527](https://github.com/woocommerce/woocommerce-ios/pull/4527) for an example of the problems this can cause.
    ///
    var htmlToAttributedString: NSAttributedString {
        precondition(Thread.isMainThread, "htmlToAttributedString should only be called from the main thread")
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

    /// Get contents between HTML tags
    ///
    func getHTMLTextContent(openingTag: String, closingTag: String) -> String? {
        let pattern: String = "\(openingTag)[^~]*?\(closingTag)"
        let regexOptions = NSRegularExpression.Options.caseInsensitive
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: regexOptions)
            guard let textCheckingResult = regex.firstMatch(
                in: self,
                options: NSRegularExpression.MatchingOptions(rawValue: UInt(0)),
                range: NSMakeRange(0, count)) else {
                return nil
            }
            let matchRange = textCheckingResult.range(at: 0)
            let match = (self as NSString).substring(with: matchRange)
            return match.removedHTMLTags.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            DDLogError("⚠️" + pattern + "<-- not found in string -->" + self )
            return nil
        }
    }
}
