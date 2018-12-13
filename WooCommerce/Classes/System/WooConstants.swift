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

    /// Jetpack Setup URL
    ///
    static let jetpackSetupUrl = "https://jetpack.com/support/getting-started-with-jetpack/"

    /// Terms of Service Website. Displayed by the Authenticator (when / if needed).
    ///
    static let termsOfServiceUrl = URL(string: "https://wordpress.com/tos/")!

    /// Cookie policy URL
    ///
    static let cookieURL = URL(string: "https://automattic.com/cookies/")!

    /// Privacy policy URL
    ///
    static let privacyURL = URL(string: "https://automattic.com/privacy/")!

    /// FAQ URL
    ///
    static let faqURL = URL(string: "https://docs.woocommerce.com/document/frequently-asked-questions")!
}
