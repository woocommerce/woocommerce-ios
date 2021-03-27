import Foundation


/// Networking Preferences
///
public struct Settings {

    /// WordPress.com API Base URL
    ///
    public static var wordpressApiBaseURL: String = {
        if ProcessInfo.processInfo.arguments.contains("mocked-wpcom-api") {
            return "http://localhost:8282/"
        }

        return "https://public-api.wordpress.com/"
    }()
}
