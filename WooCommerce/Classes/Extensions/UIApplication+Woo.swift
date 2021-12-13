import Foundation
import UIKit

// MARK: - UIApplication Utils
//
extension UIApplication {

    /// Returns the keyWindow. Accessing `UIApplication.shared.keyWindow` is deprecated from iOS 13.
    ///
    var currentKeyWindow: UIWindow? {
        UIApplication.shared.windows.filter {$0.isKeyWindow}.first
    }
}

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
