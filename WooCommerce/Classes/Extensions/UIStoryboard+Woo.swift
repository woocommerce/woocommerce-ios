import Foundation
import UIKit


// MARK: - UIStoryboard Woo Methods
//
extension UIStoryboard {

    /// Returns a (new) instance of the Dashboard Storyboard.
    ///
    static var dashboard: UIStoryboard {
        return UIStoryboard(name: "Dashboard", bundle: .main)
    }

    /// Returns a (new) instance of the Orders Storyboard.
    ///
    static var orders: UIStoryboard {
        return UIStoryboard(name: "Orders", bundle: .main)
    }
}
