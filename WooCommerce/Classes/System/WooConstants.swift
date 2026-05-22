import Foundation


/// WooCommerce Constants
///
public enum WooConstants {

    /// App Display Name, used on the About screen
    ///
    static let appDisplayName = "WooCommerce"

    /// CoreData Stack Name
    ///
    static let databaseStackName = "WooCommerce"

    /// Local SQLite Database Name
    ///
    static let localSQLiteDatabaseName = "woo-local.sqlite"

    /// Keychain Access's Service Name
    ///
    public static let keychainServiceName = "com.automattic.woocommerce"

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

    /// Store Trends Widget Identifier.
    ///
    static let storeTrendsWidgetKind = "StoreTrendsWidget"

    /// App link Widget Identifier.
    ///
    static let appLinkWidgetKind = "AppLinkWidget"

    /// Placeholder store ID to be used when the user logs in with site credentials
    ///
    static let placeholderStoreID: Int64 = -1

    /// Default store name when creating a site with free trial
    ///
    static let defaultStoreName = "Store Name"

    /// App login deep link prefix
    ///
    static let appLoginURLPrefix = "woocommerce://app-login"
    static let appMagicLoginURLPrefix = "woocommerce://magic-login"

    /// QR login deep link prefix
    ///
    static let qrLoginURLPrefix = "woocommerce://qr-login"

    /// Web page the merchant opens on a computer to display a login QR code.
    /// Surfaced (and copied to the clipboard) from the QR-login prologue.
    ///
    static let qrLoginInstructionsURL = "https://woo.com/mobilelogin"

    static let wooPaymentsPluginPath = "woocommerce-payments/woocommerce-payments.php"

    /// Key used to identify track events sent between the phone and the watch.
    ///
    static let watchTracksKey = "watch-tracks-event"

    /// Key used to identify sync request attempt from the watch.
    ///
    static let watchSyncKey = "watch-sync-event"
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

        /// More Privacy Documentation URL.
        ///
        case morePrivacyDocumentation = "https://woocommerce.com/tracking-and-opt-outs/"

        /// Documentation about WooCommerce Usage Tracking
        ///
        case usageTrackingDocumentation = "https://woocommerce.com/usage-tracking/"

        /// Privacy policy for California users URL
        ///
        case californiaPrivacy = "https://automattic.com/privacy/#california-consumer-privacy-act-ccpa"

        /// Help Center URL
        ///
        case helpCenter = "https://woocommerce.com/document/woocommerce-ios/"

        /// POS Learn More URL
        ///
        case posLearnMore = "https://woocommerce.com/mobile/pos/learn-more"

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
        case emptyStoresJetpackSetup = "https://woocommerce.com/document/jetpack-setup-instructions-for-the-woocommerce-mobile-app/"

        /// URL for in-app feedback survey
        ///
#if DEBUG
        case inAppFeedback = "https://automattic.survey.fm/woo-app-general-feedback-test-survey"
#else
        case inAppFeedback = "https://automattic.survey.fm/woo-app-general-feedback-user-survey"
#endif

        /// URL for the products feedback survey
        ///
        case productsFeedback = "https://automattic.survey.fm/woo-app-feature-feedback-products"

        /// URL for the AI Assistant beta feedback survey
        ///
        case aiAssistantFeedback = "https://automattic.survey.fm/woo-mobile-ai-assistant"

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
        case productReviewInfo = "https://woocommerce.com/document/product-reviews/"

        /// URL for troubleshooting documentation used in Error Loading Data banner
        ///
        case troubleshootErrorLoadingData = "https://woocommerce.com/document/android-ios-apps-troubleshooting-error-fetching-orders/"

        /// URL for troubleshooting documentation used in error banner when Jetpack is not connected
        ///
        case troubleshootJetpackConnection = "https://jetpack.com/support/reconnecting-reinstalling-jetpack/"

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
                "https://woocommerce.com/document/getting-started-with-in-person-payments-woopayments/"

        // swiftlint:disable:next line_length
        case inPersonPaymentsLearnMoreWCPayTapToPay = "https://woocommerce.com/document/tap-to-pay-iphone/"

        /// URL for Stripe IPP documentation
        ///
        case inPersonPaymentsLearnMoreStripe = "https://woocommerce.com/document/stripe/accept-in-person-payments-with-stripe/"

        /// Temporary redirect URL for authenticated web view when authenticating WPCom automatically
        ///
        case wpcomTempRedirectURL = "https://wordpress.com/mobile-redirect"

#if DEBUG
        case orderCreationFeedback = "https://automattic.survey.fm/woo-app-order-creation-testing"
#else
        case orderCreationFeedback = "https://automattic.survey.fm/woo-app-order-creation-production"
#endif

        /// URL for the Enable Cash on Delivery (or Pay in Person) onboarding step's learn more link using the Stripe plugin
        ///
        case stripeCashOnDeliveryLearnMore = "https://woocommerce.com/document/in-person-payments-stripe/#collect-order-payment"

        /// URL for the Enable Cash on Delivery (or Pay in Person) onboarding step's learn more link using the WCPay plugin
        ///
        case wcPayCashOnDeliveryLearnMore =
                "https://woocommerce.com/document/getting-started-with-in-person-payments-woopayments/#collect-order-payment"

        /// URL for creating a store.
        case storeCreation = "https://woocommerce.com/start"

        /// URL with un-escaped characters for testing purposes. It should read as `https://test.com/test-%E2%80%93-survey`
        ///
        case testURLStringWithSpecialCharacters = "https://test.com/test-–-survey"

        /// URL with the USPS instructions when shipping from US to EU countries with specific customs rules.
        ///
        case shippingCustomsInstructionsForEUCountries = "https://www.usps.com/international/new-eu-customs-rules.htm"

        /// URL for USPS Hazmat instructions detailing to the user the possible categories and why declaring hazmat materials is mandatory
        ///
        case uspsInstructions = "https://www.uspsdelivers.com/hazmat-shipping-safety"

        /// URL for USPS Search Tool, allowing the user to verify if the content they plan to ship is considered a Hazmat material
        ///
        case uspsSearchTool = "https://pe.usps.com/HAZMAT/Index"

        /// URL for DHL Express details over Hazmat material shippings and why the Woo Shipping doesn't currently support it
        ///
        case dhlExpressInstructions = "https://www.dhl.com/global-en/home/our-divisions/freight/customer-service/dangerous-goods-and-prohibited-items.html"

        case subscriptionsExtension = "https://woocommerce.com/products/woocommerce-subscriptions/"

        case productBundlesExtension = "https://woocommerce.com/products/product-bundles/"

        case compositeProductsExtension = "https://woocommerce.com/products/composite-products/"

        case giftCardsExtension = "https://woocommerce.com/products/gift-cards/"

        case googleAdsExtension = "https://woocommerce.com/products/google-listings-and-ads/"

        case wooPaymentsStartupGuide = "https://woocommerce.com/document/woopayments/startup-guide/"

        // swiftlint:disable:next line_length
        case wooPaymentsStartupGuideConnectWordPressComAccount = "https://woocommerce.com/document/woopayments/startup-guide/#:~:text=Enter%20your%20email%20address%20to%20connect%20to%20your%20WordPress.com%20account"

        case wooPaymentsKnowYourCustomer = "https://woocommerce.com/document/woopayments/our-policies/know-your-customer/"

        case wooCorePaymentOptions = "https://woocommerce.com/documentation/woocommerce/getting-started/sell-products/core-payment-options"

        case wooPaymentsPayoutSchedule = "https://woocommerce.com/document/woopayments/payouts/payout-schedule/"

        /// URL to learn more about Jetpack Stats
        ///
        case jetpackStats = "https://jetpack.com/stats/"

        /// URL for the Order Creation Shipping Lines feedback survey
        ///
#if DEBUG
        case orderCreationShippingFeedback = "https://automattic.survey.fm/order-creation-shipping-lines-survey-testing"
#else
        case orderCreationShippingFeedback = "https://automattic.survey.fm/order-creation-shipping-lines-survey-production"
#endif

        case ordersScreen = "https://woocommerce.com/mobile/orders"

        case customFieldsProductLearnMore = "https://woocommerce.com/document/custom-product-fields/"
        case customFieldsOrderLearnMore = "https://woocommerce.com/document/managing-orders/view-edit-or-add-an-order/#custom-fields"
        case hsTariffURL = "https://woocommerce.com/document/woocommerce-shipping-and-tax/woocommerce-shipping/#section-35"

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
