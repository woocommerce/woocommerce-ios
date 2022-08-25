import Foundation

/// For holding the custom help center content URL
/// and analytics tracking values
///
struct CustomHelpCenterContent {
    /// Custom help center web page's URL
    ///
    let helpCenterContentURL: URL

    /// Provides a dictionary for analytics tracking
    ///
    let trackingProperties: [String: String]
}

extension CustomHelpCenterContent {
    /// Initializes a `CustomHelpCenterContent` instance using `Step` and `Flow` from `AuthenticatorAnalyticsTracker`
    ///
    init?(step: String, flow: String) {
        switch step {
        case "start" where flow == "login_site_address":
            helpCenterContentURL = WooConstants.URLs.helpCenterForEnterStoreAddress.asURL()
        default:
            return nil
        }

        trackingProperties = [
            "source_step": step,
            "source_flow": flow,
            "help_content_url": helpCenterContentURL.absoluteString
        ]
    }
}
