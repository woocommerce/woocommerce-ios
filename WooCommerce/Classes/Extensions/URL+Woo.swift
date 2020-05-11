
import Foundation

/// Non-optional trusted URLs.
///
extension URL {

    /// URL pointing to woocommerce.com/blog.
    ///
    static var wooCommerceBlog: URL {
        trustedURL("https://woocommerce.com/blog/")
    }

    /// Convert a `string` to a `URL`. Crash if it is malformed.
    ///
    private static func trustedURL(_ url: String) -> URL {
        if let url = URL(string: url) {
            return url
        } else {
            fatalError("Expected URL \(url) to be a well-formed URL.")
        }
    }
}
