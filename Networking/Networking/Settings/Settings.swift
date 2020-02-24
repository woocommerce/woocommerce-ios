import Foundation


/// Networking Preferences
///
public struct Settings {

    /// UserAgent to be used for every Networking Request
    ///
    public static var userAgent = "WooCommerce iOS"

    /// WordPress.com API Base URL
    ///
    public static var wordpressApiBaseURL: String = {
        if ProcessInfo.processInfo.arguments.contains("mocked-wpcom-api") {
            return "http://localhost:8282/"
        }

        return "https://public-api.wordpress.com/"
    }()
}
