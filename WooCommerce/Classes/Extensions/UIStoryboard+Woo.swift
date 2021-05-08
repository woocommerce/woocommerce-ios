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

// MARK: UIStoryboard Helpers
//
extension UIStoryboard {
    /// Returns a view controller from a Storyboard assuming the identifier is the same as the class name.
    /// Accepts an optional creator to inject additional dependencies.
    ///
    func instantiateViewController<T: UIViewController>(ofClass classType: T.Type, creator: ((NSCoder) -> T?)? = nil) -> T {
        let identifier = classType.classNameWithoutNamespaces
        return instantiateViewController(identifier: identifier, creator: creator)
    }
}
