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
            return NSLocalizedString("Active", comment: "Application's Active State")
        case .inactive:
            return NSLocalizedString("Inactive", comment: "Application's Inactive State")
        case .background:
            return NSLocalizedString("Background", comment: "Application's Background State")
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
}
