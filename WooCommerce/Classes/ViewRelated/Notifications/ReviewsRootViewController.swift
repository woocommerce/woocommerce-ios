import UIKit

final class ReviewsRootViewController: WooNavigationController {
    init(siteID: Int64) {
        let rootViewController = ReviewsViewController(siteID: siteID)
        super.init(rootViewController: rootViewController)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
