import UIKit

final class ReviewsRootViewController: WooNavigationController {
    init(siteID: Int64) {
        guard let rootViewController = UIStoryboard.notifications.instantiateViewController(ofClass: ReviewsViewController.self) else {
            fatalError()
        }
        super.init(rootViewController: rootViewController)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
