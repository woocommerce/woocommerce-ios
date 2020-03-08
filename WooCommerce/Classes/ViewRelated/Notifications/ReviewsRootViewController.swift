import UIKit

/// The root tab controller for Reviews, a navigation controller.
/// Its root view controller displays a list of reviews.
///
final class ReviewsRootViewController: WooNavigationController {
    init() {
        let rootViewController = ReviewsViewController()
        super.init(rootViewController: rootViewController)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
