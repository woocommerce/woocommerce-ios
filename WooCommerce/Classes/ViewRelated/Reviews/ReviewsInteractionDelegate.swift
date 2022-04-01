import Foundation
import UIKit
import Yosemite

/// Adds a method to UITableViewDelegate so that we can
/// trigger navigation from its implementation
protocol ReviewsInteractionDelegate: UITableViewDelegate {
    /// Called when users pick a review from the list
    ///
    func didSelectItem(at indexPath: IndexPath, in viewController: UIViewController)

    /// Called before a cell is displayed. Provided a SyncingCoordinator,
    /// to trigger a new page load if necessary
    ///
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath, with syncingCoordinator: SyncingCoordinator)
}
