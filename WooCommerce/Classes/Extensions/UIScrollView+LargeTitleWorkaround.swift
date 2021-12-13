import UIKit

// Extension for a scroll view to be the "proxy" scroll view for the navigation bar to allow large title.
// This is a workaround for a screen with multiple scroll views in parallel (like in a tab design in Dashboard and Orders tab).
// Reference: issue 3 in p91TBi-45c-p2
extension UIScrollView {
    /// Configures a scroll view to be hidden and used to relay scroll action from any of the multiple scroll views in the view hierarchy below.
    func configureForLargeTitleWorkaround() {
        contentInsetAdjustmentBehavior = .never
        isHidden = true
        bounces = false
    }

    /// Updates the hidden scroll view from `scrollViewDidScroll` events from another `UIScrollView`.
    /// - Parameter scrollView: the scroll view where `scrollViewDidScroll` events are triggered.
    func updateFromScrollViewDidScrollEventForLargeTitleWorkaround(_ scrollView: UIScrollView) {
        contentSize = scrollView.contentSize
        contentOffset = scrollView.contentOffset
        panGestureRecognizer.state = scrollView.panGestureRecognizer.state
    }
}
