import Foundation


/// WooCommerce Constants
///
enum WooConstants {

    /// CoreData Stack Name
    ///
    static let databaseStackName = "WooCommerce"

    /// Keychain Access's Service Name
    ///
    static let keychainServiceName = "com.automattic.woocommerce"

    /// Keychain Access's Service Name for App Extensions, like the Today Stats Widget
    ///
    static let keychainServiceNameAppExtensions = "com.automattic.woocommerce.appextensions"
    
    /// Push Notifications ApplicationID
    ///
#if DEBUG
    static let pushApplicationID = "com.automattic.woocommerce:dev"
#else
    static let pushApplicationID = "com.automattic.woocommerce"
#endif
    
    /// App Group
    ///
    static let wooAppsGroup = "group.com.automattic.woocommerce"

    /// Jetpack Setup URL
    ///
    static let jetpackSetupUrl = "https://jetpack.com/support/getting-started-with-jetpack/"

    /// Terms of Service Website. Displayed by the Authenticator (when / if needed).
    ///
    static var termsOfServiceUrl: URL {
        trustedURL("https://wordpress.com/tos/")
    }

    /// Cookie policy URL
    ///
    static var cookieURL: URL {
        trustedURL("https://automattic.com/cookies/")
    }

    /// Privacy policy URL
    ///
    static var privacyURL: URL {
        trustedURL("https://automattic.com/privacy/")
    }

    /// Help Center URL
    ///
    static var helpCenterURL: URL {
        trustedURL("https://docs.woocommerce.com/document/woocommerce-ios/")
    }

    /// Feature Request URL
    ///
    static var featureRequestURL: URL {
        trustedURL("http://ideas.woocommerce.com/forums/133476-woocommerce?category_id=84283")
    }

    /// URL used for Learn More button in Orders empty state.
    ///
    static var blogURL: URL {
        trustedURL("https://woocommerce.com/blog/")
    }

    /// Number of section events required before an app review prompt appears
    ///
    static let notificationEventCount = 5

    /// Number of system-wide significant events required
    /// before an app review prompt appears
    ///
    static let systemEventCount = 10
}

// MARK: - Utils

private extension WooConstants {
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
