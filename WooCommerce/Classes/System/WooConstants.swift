import Foundation


/// WooCommerce Constants
///
enum WooConstants {

    /// App Display Name, used on the About screen
    ///
    static let appDisplayName = "WooCommerce"

    /// CoreData Stack Name
    ///
    static let databaseStackName = "WooCommerce"

    /// Keychain Access's Service Name
    ///
    static let keychainServiceName = "com.automattic.woocommerce"

    /// Keychain Access's Key for Apple ID
    ///
    static let keychainAppleIDKey = "AppleID"

    /// Keychain Access's Key for anonymous ID
    ///
    static let anonymousIDKey = "anonymousID"

    /// Keychain Access's Key for auth token
    ///
    static let authToken = "authToken"

    /// Keychain Access's Key for the current site credential password
    ///
    static let siteCredentialPassword = "siteCredentialPassword"

    /// Keychain Access's Key for the current application password
    ///
    static let applicationPassword = "ApplicationPassword"

    /// Shared UsersDefaults Suite Name
    ///
    static let sharedUserDefaultsSuiteName = "group.com.automattic.woocommerce"

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

    /// Store Info Widget Identifier.
    ///
    static let storeInfoWidgetKind = "StoreInfoWidget"

    /// App link Widget Identifier.
    ///
    static let appLinkWidgetKind = "AppLinkWidget"

    /// Placeholder store ID to be used when the user logs in with site credentials
    ///
    static let placeholderStoreID: Int64 = -1
}

// MARK: URLs
//
extension WooConstants {

    /// List of trusted URLs
    ///
    enum URLs: String, CaseIterable {

        /// "What is WordPress.com?" webpage URL.
        ///
        /// Displayed by the Authenticator in the Continue with WordPress.com flow.
        ///
        case whatIsWPCom = "https://woocommerce.com/document/what-is-a-wordpress-com-account/"

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

        /// Help Center for "Enter your Store Address" screen
        ///
        case helpCenterForEnterStoreAddress = "https://woocommerce.com/document/android-ios-apps-login-help-faq/#enter-store-address"

        /// Help Center for "Enter WordPress.com email" screen
        ///
        /// - Used for providing help in the "Enter WordPress.com email screen" when user tries to login using WordPress.com email address
        ///
        // swiftlint:disable:next line_length
        case helpCenterForWPCOMEmailScreen = "https://woocommerce.com/document/android-ios-apps-login-help-faq/#login-with-wordpress-com"

        /// Help Center for "Enter WordPress.com email" screen
        ///
        /// - Used for providing help in the "Ente WordPress.comr email screen" when user tries to login using the store address
        ///
        // swiftlint:disable:next line_length
        case helpCenterForWPCOMEmailFromSiteAddressFlow = "https://woocommerce.com/document/android-ios-apps-login-help-faq/#enter-wordpress-com-email-address-login-using-store-address-flow"

        /// Help Center for "Open magic link from email " screen
        ///
        case helpCenterForOpenEmail = "https://woocommerce.com/document/android-ios-apps-login-help-faq/#open-mail-to-find-login-link"

        /// Help Center for "Enter WordPress.com password" screen
        ///
        case helpCenterForWPCOMPasswordScreen = "https://woocommerce.com/document/android-ios-apps-login-help-faq/#enter-wordpress-com-password"

        /// Help Center for "Enter Store Credentials" screen
        ///
        case helpCenterForEnterStoreCredentials = "https://woocommerce.com/document/android-ios-apps-login-help-faq/#enter-store-credentials"

        /// Help Center for "Jetpack required error" screen
        ///
        case helpCenterForJetpackRequiredError = "https://woocommerce.com/document/android-ios-apps-login-help-faq/#jetpack-required"

        /// Help Center for "Wrong Account error" screen
        ///
        case helpCenterForWrongAccountError = "https://woocommerce.com/document/android-ios-apps-login-help-faq/#wrong-account"

        /// Help Center for No WooCommerce site error
        ///
        case helpCenterForNoWooError = "https://woocommerce.com/document/android-ios-apps-login-help-faq/#not-a-woocommerce-site"

        /// Help Center for "Store picker" screen
        ///
        case helpCenterForStorePicker = "https://woocommerce.com/document/android-ios-apps-login-help-faq/#pick-store-after-entering-password"

        /// URL used for Learn More button in Orders empty state.
        ///
        case blog = "https://woocommerce.com/blog/"

        /// Jetpack Setup URL when there are no stores available
        ///
        case emptyStoresJetpackSetup = "https://docs.woocommerce.com/document/jetpack-setup-instructions-for-the-woocommerce-mobile-app/"

        /// URL for in-app feedback survey
        ///
#if DEBUG
        case inAppFeedback = "https://automattic.survey.fm/woo-app-general-feedback-test-survey"
#else
        case inAppFeedback = "https://automattic.survey.fm/woo-app-general-feedback-user-survey"
#endif

        /// URL for the IPP feedback survey for testing purposes
        ///
#if DEBUG
        case inPersonPaymentsCashOnDeliveryFeedback = "https://automattic.survey.fm/woo-app-–-cod-survey"
        case inPersonPaymentsFirstTransactionFeedback = "https://automattic.survey.fm/woo-app-–-ipp-first-transaction-survey"
        case inPersonPaymentsPowerUsersFeedback = "https://automattic.survey.fm/woo-app-–-ipp-survey-for-power-users"
#else
        /// URL for the IPP feedback survey (COD case). Used when merchants have COD enabled, but no IPP transactions.
        ///
        case inPersonPaymentsCashOnDeliveryFeedback = "https://automattic.survey.fm/woo-app-–-cod-survey"

        /// URL for IPP feedback survey (First Transaction case). Used when merchants have only a few IPP transactions.
        ///
        case inPersonPaymentsFirstTransactionFeedback = "https://automattic.survey.fm/woo-app-–-ipp-first-transaction-survey"

        /// URL for IPP feedback survey (Power Users case).  Used when merchants have a significant number of IPP transactions.
        ///
        case inPersonPaymentsPowerUsersFeedback = "https://automattic.survey.fm/woo-app-–-ipp-survey-for-power-users"
#endif

        /// URL for the Tap to Pay first payment survey
        ///
#if DEBUG
        case tapToPayFirstPaymentFeedback = "https://automattic.survey.fm/woo-app-tap-to-pay-survey"
#else
        case tapToPayFirstPaymentFeedback = "https://automattic.survey.fm/woo-app-–-first-ttp-survey"
#endif

        /// URL for the products feedback survey
        ///
        case productsFeedback = "https://automattic.survey.fm/woo-app-feature-feedback-products"

        /// URL for the store setup feedback survey
        ///
#if DEBUG
        case storeSetupFeedback = "https://automattic.survey.fm/testing-debug-woo-mobile-–-store-setup-survey-2022"
#else
        case storeSetupFeedback = "https://automattic.survey.fm/woo-mobile-–-store-setup-survey-2022"
#endif

        /// URL for the shipping labels M3 feedback survey
        ///
#if DEBUG
        case shippingLabelsRelease3Feedback = "https://automattic.survey.fm/woo-app-testing-feature-feedback-shipping-labels"
#else
        case shippingLabelsRelease3Feedback = "https://automattic.survey.fm/woo-app-feature-feedback-shipping-labels"
#endif

        /// URL for the order add-on i1 feedback survey
        ///
#if DEBUG
        case orderAddOnI1Feedback = "https://automattic.survey.fm/woo-app-addons-testing"
#else
        case orderAddOnI1Feedback = "https://automattic.survey.fm/woo-app-addons-production"
#endif

        /// URL for shipping label creation information
        ///
        case shippingLabelCreationInfo = "https://woocommerce.com/products/shipping"

        /// URL for product review information
        ///
        case productReviewInfo = "https://woocommerce.com/posts/reviews-woocommerce-best-practices/"

        /// URL for troubleshooting documentation used in Error Loading Data banner
        ///
        case troubleshootErrorLoadingData = "https://docs.woocommerce.com/document/android-ios-apps-troubleshooting-error-fetching-orders/"

        /// URL for roles and permissions information
        ///
        case rolesAndPermissionsInfo = "https://woocommerce.com/posts/a-guide-to-woocommerce-user-roles-permissions-and-security/"

        /// URL for making the login on WordPress.com
        ///
        case loginWPCom = "https://wordpress.com/wp-login.php"

        /// URL for adding a payment method in WCShip extension
        ///
        case addPaymentMethodWCShip = "https://wordpress.com/me/purchases/add-payment-method"

        /// URLs for WCPay IPP documentation
        ///
        case inPersonPaymentsLearnMoreWCPay =
                "https://woocommerce.com/document/woocommerce-payments/in-person-payments/getting-started-with-in-person-payments/"

        // swiftlint:disable:next line_length
        case inPersonPaymentsLearnMoreWCPayTapToPay = "https://woocommerce.com/document/woocommerce-payments/in-person-payments/woocommerce-in-person-payments-tap-to-pay-on-iphone-quick-start-guide/"

        /// URL for Stripe IPP documentation
        ///
        case inPersonPaymentsLearnMoreStripe = "https://docs.woocommerce.com/document/stripe/accept-in-person-payments-with-stripe/"

        /// URL for the order creation feedback survey (full order creation and simple payments)
        ///
#if DEBUG
        case orderCreationFeedback = "https://automattic.survey.fm/woo-app-order-creation-testing"
#else
        case orderCreationFeedback = "https://automattic.survey.fm/woo-app-order-creation-production"
#endif

#if DEBUG
        case couponManagementFeedback = "https://automattic.survey.fm/woo-app-coupon-management-testing"
#else
        case couponManagementFeedback = "https://automattic.survey.fm/woo-app-coupon-management-production"
#endif
        /// URL for the Enable Cash on Delivery (or Pay in Person) onboarding step's learn more link using the Stripe plugin
        /// 
        case stripeCashOnDeliveryLearnMore = "https://woocommerce.com/document/stripe/accept-in-person-payments-with-stripe/#section-8"

        /// URL for the Enable Cash on Delivery (or Pay in Person) onboarding step's learn more link using the WCPay plugin
        ///
        case wcPayCashOnDeliveryLearnMore =
                "https://woocommerce.com/document/payments/getting-started-with-in-person-payments-with-woocommerce-payments/#add-cod-payment-method"

        /// URL for creating a store.
        case storeCreation = "https://woocommerce.com/start"

        /// URL with un-escaped characters for testing purposes. It should read as `https://test.com/test-%E2%80%93-survey`
        ///
        case testURLStringWithSpecialCharacters = "https://test.com/test-–-survey"

        /// Returns the URL version of the receiver
        ///
        func asURL() -> URL {
            Self.trustedURL(self.rawValue)
        }
    }
}

// MARK: - Utils

private extension WooConstants.URLs {
    /// Convert a `string` to a `URL`. Crash if it is malformed.
    ///
    private static func trustedURL(_ url: String) -> URL {

        if let url = URL(string: url) {
            return url
        } else if let escapedString = url.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed),
                  let escapedURL = URL(string: escapedString) {
            return escapedURL
        } else {
            fatalError("Expected URL \(url) to be a well-formed URL.")
        }
    }
}
