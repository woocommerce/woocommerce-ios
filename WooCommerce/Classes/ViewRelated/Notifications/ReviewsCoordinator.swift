
import Foundation
import UIKit

/// Coordinator for the Reviews tab.
/// 
final class ReviewsCoordinator: Coordinator {
    var navigationController: UINavigationController

    init() {
        self.navigationController = WooNavigationController(rootViewController: ReviewsViewController())
    }

    func start() {
        // noop
    }
}
