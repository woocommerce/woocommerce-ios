import Foundation
import UIKit


// MARK: - UIApplication.State Woo Methods
//
extension UIApplication.State {

    /// Returns a String Description of the re3ceiver
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
