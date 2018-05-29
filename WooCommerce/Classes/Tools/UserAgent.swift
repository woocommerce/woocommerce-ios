import Foundation
import UIKit


/// WooCommerce User Agent!
///
class UserAgent {

    /// Private: NO-OP
    ///
    private init() { }


    /// Returns the WooCommerce User Agent
    ///
    static var defaultUserAgent: String = {
        return webkitUserAgent + " " + Constants.woocommerceIdentifier + "/" + bundleShortVersion
    }()

    /// Returns the WebKit User Agent
    ///
    private static var webkitUserAgent: String {
        return UIWebView().stringByEvaluatingJavaScript(from: Constants.loadUserAgentScript) ?? String()
    }

    /// Returns the Bundle Version ID
    ///
    private static var bundleShortVersion: String {
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

        /// Load User Agent JS Script
        ///
        static let loadUserAgentScript = "navigator.userAgent"

        /// Short Version Key
        ///
        static let shortVersionKey = "CFBundleShortVersionString"
    }
}
