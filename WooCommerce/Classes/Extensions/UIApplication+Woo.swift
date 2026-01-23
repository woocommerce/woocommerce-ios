import Foundation
import UIKit

// MARK: - UIApplication.State Woo Methods
//
extension UIApplication.State {

    /// Returns a String Description of the receiver
    ///
    var description: String {
        switch self {
        case .active:
            return NSLocalizedString("Active", comment: "This text appears as a status label in three different contexts: indicating that coupons are currently valid and usable, showing that subscriptions are currently active and ongoing, and displaying the application's active state for debugging purposes.")
        case .inactive:
            return NSLocalizedString("Inactive", comment: "Application's Inactive State")
        case .background:
            return NSLocalizedString("Background", comment: "This text appears as a debug or diagnostic label indicating when the WooCommerce app is running in the background state (not actively visible to the user). It's likely used in developer tools, logs, or technical status displays within the app.")
        default:
            return NSLocalizedString("Unknown", comment: "Unknown Application State")
        }
    }
}

extension UIApplication {
    /// Returns the current key window from the connected window scenes.
    static var wooKeyWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
    }

    /// Returns the delegate of the first connected scene.
    ///
    /// - Note: This approach is valid while the app supports only a single scene.
    ///       If multi‑window support is introduced in the future,
    ///       this will need to be revisited to handle multiple scenes safely.
    static var sceneDelegate: SceneDelegate? {
        UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .compactMap({ $0.delegate as? SceneDelegate })
            .first
    }
}
