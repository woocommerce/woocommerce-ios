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

    /// Push Notifications ApplicationID
    ///
#if DEBUG
    static let pushApplicationID = "com.automattic.woocommerce:dev"
#else
    static let pushApplicationID = "com.automattic.woocommerce"
#endif

    /// Number of section events required before an app review prompt appears
    ///
    static let notificationEventCount = 5

    /// Number of system-wide significant events required
    /// before an app review prompt appears
    ///
    static let systemEventCount = 10
}

// MARK: URLs
//
extension WooConstants {

    /// List of thrusted URLs
    ///
    enum URLs: String, CaseIterable {

        /// Jetpack Setup URL
        ///
        case jetpackSetup = "https://jetpack.com/support/getting-started-with-jetpack/"

        /// Terms of Service Website. Displayed by the Authenticator (when / if needed).
        ///
        case termsOfService = "https://wordpress.com/tos/"

        /// Cookie policy URL
        ///
        case cookie = "https://automattic.com/cookies/"

        /// Privacy policy URL
        ///
        case privacy = "https://automattic.com/privacy/"

        /// Privacy policy for California users URL
        ///
        case californiaPrivacy = "https://automattic.com/privacy/#california-consumer-privacy-act-ccpa"

        /// Help Center URL
        ///
        case helpCenter = "https://docs.woocommerce.com/document/woocommerce-ios/"

        /// Feature Request URL
        ///
        case featureRequest = "http://ideas.woocommerce.com/forums/133476-woocommerce?category_id=84283"

        /// URL used for Learn More button in Orders empty state.
        ///
        case blog = "https://woocommerce.com/blog/"

        /// URL for in-app feedback survey
        ///
#if DEBUG
        case inAppFeedback = "https://wasseryi.survey.fm/woo-mobile-app-test-survey"
#else
        case inAppFeedback = "https://automattic.survey.fm/woo-app-general-feedback-user-survey"
#endif

        /// Returns the URL version of the receiver
        ///
        func asURL() -> URL {
            WooConstants.trustedURL(self.rawValue)
        }
    }
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
