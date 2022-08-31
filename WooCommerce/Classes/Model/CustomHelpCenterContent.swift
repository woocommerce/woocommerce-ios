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

// MARK: Initializer for WordPressAuthenticator screens
//
extension CustomHelpCenterContent {
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

// MARK: Initializer for WCiOS screens
//
extension CustomHelpCenterContent {
    /// Screens related to login/authentication
    ///  These screens are from WCiOS codebase and they don't exist in WordPressAuthenticator library
    ///
    enum Screen {
        /// Jetpack required error screen presented using `JetpackErrorViewModel`
        ///
        case jetpackRequired
    }

    init(screen: Screen, flow: AuthenticatorAnalyticsTracker.Flow) {
        let step: String
        switch screen {
        case .jetpackRequired:
            step = "jetpack_not_connected" // Matching Android `Step` value
            url = WooConstants.URLs.helpCenterForJetpackRequiredError.asURL()
        }

        trackingProperties = [
            Key.step.rawValue: step,
            Key.flow.rawValue: flow.rawValue,
            Key.url.rawValue: url.absoluteString
        ]
    }
}

/// Used for tracking analytics events
///
private enum Key: String {
    case step = "source_step"
    case flow = "source_flow"
    case url = "help_content_url"
}
