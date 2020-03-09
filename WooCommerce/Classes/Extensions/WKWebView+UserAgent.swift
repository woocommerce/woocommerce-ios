import WebKit
import AutomatticTracks

/// This extension provides a mechanism to request the UserAgent for WKWebViews
///
extension WKWebView {
    private static let userAgentKey = "_userAgent"

    /// Call this method to get the user agent for the WKWebView
    ///
    var userAgent: String {
        guard let userAgent = value(forKey: WKWebView.userAgentKey) as? String,
            userAgent.count > 0 else {
                CrashLogging.logMessage(
                    "This method for retrieving the user agent seems to be no longer working.  We need to figure out an alternative.",
                    properties: [:],
                    level: .error)
                return ""
        }

        return userAgent
    }

    /// Static version of the method that returns the current user agent.
    ///
    static var userAgent: String {
        return WKWebView().userAgent
    }
}
