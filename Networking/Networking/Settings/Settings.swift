import Foundation


/// Networking Preferences
///
public struct Settings {

    /// WordPress.com API Base URL
    ///
    public static func wordpressApiBaseURL(wpComSandboxUsername: String? = nil) -> String {
        if ProcessInfo.processInfo.arguments.contains("mocked-wpcom-api") {
            return "http://localhost:8282/"
        } else if let wpComSandboxUsername = wpComSandboxUsername {
            return "https://\(wpComSandboxUsername).dev.dfw.wordpress.com/sandboxed-api/"
        }

        return "https://public-api.wordpress.com/"
    }
}
