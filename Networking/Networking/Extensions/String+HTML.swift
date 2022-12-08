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

    /// Removes the given prefix from the string, if exists.
    ///
    /// Calling this method might invalidate any existing indices for use with this string.
    ///
    /// - Parameters:
    ///     - prefix: A possible prefix to remove from this string.
    ///
    mutating func removePrefix(_ prefix: String) {
        if let prefixRange = range(of: prefix), prefixRange.lowerBound == startIndex {
            removeSubrange(prefixRange)
        }
    }

    /// Returns a string with the given prefix removed, if it exists.
    ///
    /// - Parameters:
    ///     - prefix: A possible prefix to remove from this string.
    ///
    func removingPrefix(_ prefix: String) -> String {
        var copy = self
        copy.removePrefix(prefix)
        return copy
    }
}
