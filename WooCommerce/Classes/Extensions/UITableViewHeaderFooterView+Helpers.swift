import Foundation
import UIKit


/// UITableViewHeaderFooterView Helpers
///
extension UITableViewHeaderFooterView {

    /// Returns a reuseIdentifier that matches the receiver's classname (non namespaced).
    ///
    class var reuseIdentifier: String {
        return classNameWithoutNamespaces
    }
}
