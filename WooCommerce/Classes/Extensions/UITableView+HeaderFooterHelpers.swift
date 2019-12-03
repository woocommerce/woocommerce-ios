import UIKit

extension UITableView {
    /// Called in view controller's `viewDidLayoutSubviews`. If table view has a footer view, calculates the new height.
    /// If new height is different from current height, updates the footer view with the new height and reassigns the table footer view.
    /// Note: make sure the top-level footer view (`tableView.tableFooterView`) is frame based as a container of the Auto Layout based subview.
    func updateFooterHeight() {
        if let footerView = tableFooterView {
            let targetSize = CGSize(width: footerView.frame.width, height: 0)
            let newSize = footerView.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: .required, verticalFittingPriority: .defaultLow)
            let newHeight = newSize.height
            var currentFrame = footerView.frame
            if newHeight != currentFrame.size.height {
                currentFrame.size.height = newHeight
                footerView.frame = currentFrame
                tableFooterView = footerView
            }
        }
    }

    /// Called in view controller's `viewDidLayoutSubviews`. If table view has a header view, calculates the new height.
    /// If new height is different from current height, updates the header view with the new height and reassigns the table header view.
    /// Note: make sure the top-level header view (`tableView.tableHeaderView`) is frame based as a container of the Auto Layout based subview.
    func updateHeaderHeight() {
        if let headerView = tableHeaderView {
            let targetSize = CGSize(width: headerView.frame.width, height: 0)
            let newSize = headerView.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: .required, verticalFittingPriority: .defaultLow)
            let newHeight = newSize.height
            var currentFrame = headerView.frame
            if newHeight != currentFrame.size.height {
                currentFrame.size.height = newHeight
                headerView.frame = currentFrame
                tableHeaderView = headerView
            }
        }
    }

    /// Removes the separator of the last cell.
    ///
    func removeLastCellSeparator() {
        tableFooterView = UIView(frame: CGRect(origin: .zero,
                                               size: CGSize(width: frame.width, height: 1)))
    }
}
