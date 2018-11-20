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

    /// Jetpack Setup URL
    ///
    static let jetpackSetupUrl = "https://jetpack.com/support/getting-started-with-jetpack/"

    /// Terms of Service Website. Displayed by the Authenticator (when / if needed).
    ///
    static let termsOfServiceUrl = "https://wordpress.com/tos/"

    /// Support Email
    ///
    static let supportMail = "mobile-support@woocommerce.com"

    /// Cookie policy URL
    ///
    static let cookieURL = URL(string: "https://automattic.com/cookies/")

    /// Privacy policy URL
    ///
    static let privacyURL = URL(string: "https://automattic.com/privacy/")

    /// FAQ URL
    ///
    static let faqURL = URL(string: "https://docs.woocommerce.com/document/frequently-asked-questions")
}
