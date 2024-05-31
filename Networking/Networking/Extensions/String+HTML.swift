import Foundation

import class Aztec.HTMLParser

/// String: HTML Stripping
///
extension String {

    /// Returns the HTML Stripped version of the receiver.
    ///
    /// NOTE: I can be very slow ⏳ — using it in a background thread is strongly recommended.
    ///
    public var strippedHTML: String {
        HTMLParser().parse(self).rawText()
    }
}
