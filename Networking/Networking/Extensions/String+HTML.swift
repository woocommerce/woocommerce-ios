import Foundation

#if canImport(Aztec)
import class Aztec.HTMLParser
#endif

/// String: HTML Stripping
///
extension String {

    /// Returns the HTML Stripped version of the receiver.
    ///
    /// NOTE: I can be very slow ⏳ — using it in a background thread is strongly recommended.
    ///
    public var strippedHTML: String {
#if canImport(Aztec)
        HTMLParser().parse(self).rawText()
#else
        // This conditional compiling is because Aztec is not available on WatchOS and our watch app does not access this code yet.
        // We should consider adding HTML-stripping support when needed.
        return self
#endif
    }
}
