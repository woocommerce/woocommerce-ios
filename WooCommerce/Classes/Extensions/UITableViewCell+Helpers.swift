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

    /// Returns the separator used to divide the section header view and the first cell on a
    /// section.
    ///
    /// This only returns the separator (`UIView`) if:
    ///
    /// 1. This function is called during `layoutSubviews()`. 
    /// 2. This cell belongs to a grouped `UITableView`.
    /// 3. This cell is the first cell in a section.
    ///
    /// - Complexity: O(*n*), where *n* is the total number of `subviews` of this cell.
    ///
    func findSectionTopSeparator() -> UIView? {
        subviews.first {
            let subviewFrame = $0.frame

            // We use `height < 1` since we assume that the separator is always `0.5` and using
            // `< 1` seems like a safer predicate to use.
            //
            // This is going to blow up in our face if:
            //
            // - The separator's height changes in the future.
            // - There is another subview that has the same frame.
            //
            return subviewFrame.origin == .zero
                && subviewFrame.width == bounds.width
                && subviewFrame.height < 1
        }
    }
}
