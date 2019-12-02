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

    /// Called when we want to present a review after receiving a push notification
    ///
    func presentReviewDetails(for noteId: Int, in viewController: UIViewController)
}


/// Abstracts the datasource used to render the Product Review list
protocol ReviewsDataSource: UITableViewDataSource, ReviewsInteractionDelegate {

    /// Boolean indicating if there are reviews
    ///
    var isEmpty: Bool { get }

    /// Identifiers of the Products mentioned in the reviews.
    /// Guaranteed to be uniqued (does not contain duplicates)
    ///
    var reviewsProductsIDs: [Int] { get }

    /// Number of reviews in memory
    ///
    var reviewCount: Int { get }

    /// Notifications associated with the reviews.
    /// We need to expose them in order to mark them as read
    ///
    var notifications: [Note] { get }

    /// Initializes observers for incoming reviews
    ///
    func observeReviews() throws

    /// Starts forwarding events to the tableview
    ///
    func startForwardingEvents(to tableView: UITableView)

    /// Force a refresh of entities obeserving data collections
    ///
    func refreshDataObservers()

    /// Cancels forwarding events to any previously registered table view
    ///
    func stopForwardingEvents()
}
