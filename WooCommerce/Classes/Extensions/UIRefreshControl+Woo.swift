import UIKit

extension UIRefreshControl {
    /// Reset animation of refresh control by forcing refreshing animation again
    func resetAnimation(in scrollView: UIScrollView, completion: (() -> Void)? = nil) {
        if isRefreshing {
            endRefreshing()
            scrollView.setContentOffset(CGPoint(x: 0, y: scrollView.contentOffset.y - frame.size.height), animated: true)
            beginRefreshing()
            completion?()
        }
    }

    /// Manually triggers the refresh animation and scrolls the table view to make it visible.
    ///
    func showRefreshAnimation(on tableView: UITableView) {
        DispatchQueue.main.async {
            self.beginRefreshing()

            // Apply some offset so that the refresh control can actually be seen
            // But only if the table is already at the top of to not disrupt any scrolling offset.
            if tableView.contentOffset.y == 0 {
                let contentOffset = CGPoint(x: 0, y: -self.frame.height)
                tableView.setContentOffset(contentOffset, animated: true)
            }
        }
    }
}
