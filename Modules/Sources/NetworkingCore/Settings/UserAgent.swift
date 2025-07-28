#if canImport(WebKit)
import WebKit
#endif

#if canImport(WatchKit)
import WatchKit
#endif


/// WooCommerce User Agent!
///
public class UserAgent {

    /// Returns the default WooCommerce iOS User Agent
    ///
    public static var defaultUserAgent: String = {
        return webkitUserAgent + " " + Constants.woocommerceIdentifier + "/" + bundleShortVersion
    }()

    /// Returns a user agent string similar to (but may not exactly match) the one used in `WKWebView`.
    ///
    static var webkitUserAgent: String = {
        // Examples user agent strings from `WKWebView` in iOS simulators:
        //
        // ## iPhone 15 Pro (iOS 17.2)
        // Mozilla/5.0 (iPhone; CPU iPhone OS 17_2 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148
        //
        // ## iPad Pro (iOS 17.0.1)
        // Mozilla/5.0 (iPad; CPU OS 17_0_1 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148
        //
        // Based on the WebKit implementation[^1], most of the components are hardcoded, and there are only a couple of dynamic components:
        // 1. Device model. i.e. iPhone/iPad
        // 2. OS name and version. i.e. iPhone OS 17_2
        //
        // Please note the "Mobile/15E148" part is WKWebView's default and hardcoded "application name"[^2].
        //
        // [^1]: https://github.com/WebKit/WebKit/blob/5fbb03ee1c6210c79779d6fa1a9e7290daa746d1/Source/WebCore/platform/ios/UserAgentIOS.mm#L88-L113
        // [^2]: https://github.com/WebKit/WebKit/blob/492140d27dbe/Source/WebKit/UIProcess/API/Cocoa/WKWebViewConfiguration.mm#L612

        let deviceModel = device.model // Example: "iPhone"
        var osName = device.systemName // Example: "iPhone OS"
        let osVersion = device.systemVersion.replacingOccurrences(of: ".", with: "_") // Example: "17_2"

        // WKWebView on iPad uses a static user agent.
        // https://github.com/WebKit/WebKit/blob/6a053cfb431bd70d5017ba881a39f004e52effc2/Source/WebCore/platform/ios/UserAgentIOS.mm#L97
        if device.isPad {
            osName = "OS"
        }

        // Use "iPhone OS" instead of "iOS", because that's what WKWebView uses.
        if osName == "iOS" {
            osName = "iPhone OS"
        }

        return "Mozilla/5.0 (\(deviceModel); CPU \(osName) \(osVersion) like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Mobile/15E148"
    }()

    /// Returns the Bundle Version ID
    ///
    public static var bundleShortVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: Constants.shortVersionKey) as? String
        return version ?? String()
    }

    /// Returns the
    ///
    private static var device: AppleDevice {
#if !os(watchOS)
        return UIDevice.current
#endif
#if os(watchOS)
        return WKInterfaceDevice.current()
#endif
    }
}


// MARK: - Nested Types
//
private extension UserAgent {

    struct Constants {

        /// WC UserAgent Prefix
        ///
        static let woocommerceIdentifier = "wc-ios"

        /// User Agent Key
        ///
        static let userAgentKey = "_userAgent"

        /// Short Version Key
        ///
        static let shortVersionKey = "CFBundleShortVersionString"
    }
}


/// Protocol to abstract an `UIDevice` and `WKInterfaceDevice` behind the same interface.
///
private protocol AppleDevice {
    var model: String { get }
    var systemName: String { get }
    var systemVersion: String { get }
    var isPad: Bool { get }
}

#if !os(watchOS)
extension UIDevice: AppleDevice {
    var isPad: Bool {
        return userInterfaceIdiom == .pad
    }
}
#endif

#if os(watchOS)
extension WKInterfaceDevice: AppleDevice {
    var isPad: Bool {
        false
    }
}
#endif
