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
    ///
    /// - Important: Crashes if the value is missing or empty — this is a developer error
    ///   indicating the xcconfig is misconfigured.
    var dotcomAuthScheme: String {
        guard let scheme = object(forInfoDictionaryKey: "WCDotcomAuthScheme") as? String, !scheme.isEmpty else {
            fatalError("WCDotcomAuthScheme is missing or empty in Info.plist. Check the xcconfig setup.")
        }
        return scheme
    }

    /// Google Sign-In URL scheme, read from Info.plist (`WCGoogleAuthScheme`).
    ///
    /// - Important: Crashes if the value is missing or empty — this is a developer error
    ///   indicating the xcconfig is misconfigured.
    var googleAuthScheme: String {
        guard let scheme = object(forInfoDictionaryKey: "WCGoogleAuthScheme") as? String, !scheme.isEmpty else {
            fatalError("WCGoogleAuthScheme is missing or empty in Info.plist. Check the xcconfig setup.")
        }
        return scheme
    }
}
