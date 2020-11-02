import WebKit

/// WooCommerce User Agent!
///
public class UserAgent {

    /// Returns the default WooCommerce iOS User Agent
    ///
    public static var defaultUserAgent: String = {
        return webkitUserAgent + " " + Constants.woocommerceIdentifier + "/" + bundleShortVersion
    }()

    /// Returns the WebKit User Agent
    ///
    static var webkitUserAgent: String {
        guard let userAgent = WKWebView().value(forKey: Constants.userAgentKey) as? String,
            !userAgent.isEmpty else {
                return ""
        }
        return userAgent
    }

    /// Returns the Bundle Version ID
    ///
    public static var bundleShortVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: Constants.shortVersionKey) as? String
        return version ?? String()
    }
}


// MARK: - Nested Types
//
private extension UserAgent {

    struct Constants {

        /// WC UserAgent Prefix
        ///
        static let woocommerceIdentifier = "wc-ios"

        /// User Agent Key
        ///
        static let userAgentKey = "_userAgent"

        /// Short Version Key
        ///
        static let shortVersionKey = "CFBundleShortVersionString"
    }
}
