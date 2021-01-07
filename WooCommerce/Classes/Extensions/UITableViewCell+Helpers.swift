import Foundation
import UIKit


/// UITableViewCell Helpers
///
extension UITableViewCell {

    /// Returns a reuseIdentifier that matches the receiver's classname (non namespaced).
    ///
    class var reuseIdentifier: String {
        return classNameWithoutNamespaces
    }

    /// Applies the default background color
    ///
    func applyDefaultBackgroundStyle() {
        backgroundColor = .listForeground
    }

    /// Hides the separator for a cell.
    /// Be careful applying this to a reusable cell where the separator is expected to be shown in some cases.
    ///
    func hideSeparator() {
        separatorInset = UIEdgeInsets(top: 0, left: separatorInset.left, bottom: 0, right: .greatestFiniteMagnitude)
    }

    /// Shows the separator for a cell.
    /// The separator inset is only set manually when a custom inset is preferred, or the cell is reusable with a different inset in other use cases.
    ///
    func showSeparator(inset: UIEdgeInsets = .init(top: 0, left: 16, bottom: 0, right: 0)) {
        separatorInset = inset
    }
}
