import Foundation
import UIKit


/// Bundle: Woo Methods
///
extension Bundle {

    /// Returns the Bundle Version. If the value cannot be found, this method will return an empty string.
    ///
    var version: String {
        let version = infoDictionary?[String(kCFBundleVersionKey)] as? String
        return version ?? ""
    }

    /// WordPress.com Magic Link URL scheme, read from Info.plist (`WCDotcomAuthScheme`).
    var dotcomAuthScheme: String {
        requiredNonEmptyInfoPlistString(for: "WCDotcomAuthScheme")
    }

    /// Google Sign-In URL scheme, read from Info.plist (`WCGoogleAuthScheme`).
    var googleAuthScheme: String {
        requiredNonEmptyInfoPlistString(for: "WCGoogleAuthScheme")
    }

    /// Reads a `String` value from Info.plist and crashes if it is missing or empty.
    ///
    /// Use this for values that must be wired up at build time via xcconfig.
    /// A crash on first launch makes misconfiguration obvious immediately.
    private func requiredNonEmptyInfoPlistString(for key: String) -> String {
        guard let value = object(forInfoDictionaryKey: key) as? String, !value.isEmpty else {
            fatalError("\(key) is missing or empty in Info.plist. Check the xcconfig setup.")
        }
        return value
    }
}
