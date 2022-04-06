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

/// Implement this protocol to add an extra layer of customization to the the
/// ReviewsDataSource
protocol ReviewsDataSourceCustomizing: AnyObject {
    /// Whether it should show the product title on cell or not
    ///
    var shouldShowProductTitleOnCells: Bool { get }

    /// Implement this method to return the predicate that will provide reviews.
    ///
    /// - parameter sitePredicate: This predicate adds a site constraint. By composing your predicate with it you will retrieve only reviews of that site.
    ///
    func reviewsFilterPredicate(with sitePredicate: NSPredicate) -> NSPredicate
}

/// Abstracts the dataSource used to render the Product Review list
protocol ReviewsDataSource: UITableViewDataSource, ReviewsInteractionDelegate {
    /// Boolean indicating if there are reviews
    ///
    var isEmpty: Bool { get }

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

    /// Force a refresh of entities observing data collections
    ///
    func refreshDataObservers()
}
