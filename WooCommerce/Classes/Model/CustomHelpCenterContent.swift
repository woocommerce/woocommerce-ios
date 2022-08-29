import Foundation
import WordPressAuthenticator

/// For holding the custom help center content URL
/// and analytics tracking values
///
struct CustomHelpCenterContent {
    /// Custom help center web page's URL
    ///
    let url: URL

    /// Provides a dictionary for analytics tracking
    ///
    let trackingProperties: [String: String]
}

extension CustomHelpCenterContent {
    /// Used for tracking analytics events
    ///
    enum Key: String {
        case step = "source_step"
        case flow = "source_flow"
        case url = "help_content_url"
    }

    /// Initializes a `CustomHelpCenterContent` instance using `Step` and `Flow` from `AuthenticatorAnalyticsTracker`
    ///
    init?(step: AuthenticatorAnalyticsTracker.Step, flow: AuthenticatorAnalyticsTracker.Flow) {
        switch step {
        case .start where flow == .loginWithSiteAddress: // Enter Store Address screen
            url = WooConstants.URLs.helpCenterForEnterStoreAddress.asURL()
        case .enterEmailAddress where flow == .loginWithSiteAddress: // Enter WordPress.com email screen from store address flow
            url = WooConstants.URLs.helpCenterForWPCOMEmailFromSiteAddressFlow.asURL()
        case .enterEmailAddress where flow == .wpCom: // Enter WordPress.com email screen from store WPCOM email flow
            url = WooConstants.URLs.helpCenterForWPCOMEmailScreen.asURL()
        case .usernamePassword: // Enter Store credentials screen (wp-admin creds)
            url = WooConstants.URLs.helpCenterForEnterStoreCredentials.asURL()
        default:
            return nil
        }

        trackingProperties = [
            Key.step.rawValue: step.rawValue,
            Key.flow.rawValue: flow.rawValue,
            Key.url.rawValue: url.absoluteString
        ]
    }
}
