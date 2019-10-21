import Foundation
import UIKit

// MARK: - UINavigationController: Woo Extensions
//
extension UINavigationController {

    /// Whenever there's a single viewController onscreen, this method will set the "Top" UIScrollView's
    /// Content Offset to zero.
    ///
    func scrollContentToTop(animated: Bool) {
        guard viewControllers.count == 1,
            let scrollView = visibleViewController?.view?.subviews.first as? UIScrollView
        else {
            return
        }

        scrollView.setContentOffset(.zero, animated: animated)
    }
}
