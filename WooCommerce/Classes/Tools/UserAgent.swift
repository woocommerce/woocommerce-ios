import Foundation
import UIKit
import WebKit


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
    static var webkitUserAgent: String {
        guard let userAgent = WKWebView().value(forKey: Constants.userAgentKey) as? String,
            userAgent.isNotEmpty else {
                return ""
        }
        return userAgent
    }

    /// Returns the Bundle Version ID
    ///
    static var bundleShortVersion: String {
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
