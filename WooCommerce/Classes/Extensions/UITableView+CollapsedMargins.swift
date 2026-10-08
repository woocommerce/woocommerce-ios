import UIKit

extension UITableView {
    /// On iPhone Duo (iOS 27.1) the table zeroes its default margin on the sides inset from the window edge (WOOMOB-4267, WOOMOB-4303).
    /// Sets explicit symmetric horizontal margins when a side collapsed; leaves already symmetric margins untouched.
    /// Call from `viewDidLayoutSubviews`, passing the view controller's `systemMinimumLayoutMargins` as the fallback.
    func restoreCollapsedLayoutMarginsIfNeeded(systemMinimumLayoutMargins: NSDirectionalEdgeInsets) {
        let margins = layoutMargins
        let safeAreaInsets = safeAreaInsets
        let left = margins.left - safeAreaInsets.left
        let right = margins.right - safeAreaInsets.right
        guard abs(left - right) > Constants.marginTolerance || left <= 0 else {
            return
        }

        let widestMargin = max(left, right)
        let horizontalMargin = widestMargin > 0 ? widestMargin : max(systemMinimumLayoutMargins.leading, systemMinimumLayoutMargins.trailing)
        guard horizontalMargin > 0 else {
            return
        }
        layoutMargins = UIEdgeInsets(top: margins.top - safeAreaInsets.top,
                                     left: horizontalMargin,
                                     bottom: margins.bottom - safeAreaInsets.bottom,
                                     right: horizontalMargin)
    }
}

private enum Constants {
    static let marginTolerance = CGFloat(0.5)
}
