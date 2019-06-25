import UIKit

extension UIViewController {
    /// Called in `viewDidLayoutSubviews`. If input table view has a footer view, calculates the new height.
    /// If new height is different from current height, updates the footer view with the new height and reassigns the table footer view.
    /// Note: make sure the top-level footer view (`tableView.tableFooterView`) is frame based as a container of the Auto Layout based subview.
    ///
    /// - Parameter tableView: a table view that is a subview of the view controller.
    func updateFooterHeight(for tableView: UITableView) {
        if let footerView = tableView.tableFooterView {
            let targetSize = CGSize(width: footerView.frame.width, height: 0)
            let newSize = footerView.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: .required, verticalFittingPriority: .defaultLow)
            let newHeight = newSize.height
            var currentFrame = footerView.frame
            if newHeight != currentFrame.size.height {
                currentFrame.size.height = newHeight
                footerView.frame = currentFrame
                tableView.tableFooterView = footerView
            }
        }
    }
}
