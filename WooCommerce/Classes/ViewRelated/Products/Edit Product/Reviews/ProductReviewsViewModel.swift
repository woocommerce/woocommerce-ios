import Foundation
import UIKit
import WordPressUI
import Yosemite
import class AutomatticTracks.CrashLogging

/// The Product Reviews view model used in ProductReviewsViewController
final class ProductReviewsViewModel {
    private let data: ReviewsDataSource

    var isEmpty: Bool {
        return data.isEmpty
    }

    var dataSource: UITableViewDataSource {
        return data
    }

    var delegate: ReviewsInteractionDelegate {
        return data
    }

    init(data: ReviewsDataSource) {
        self.data = data
    }

    func displayPlaceholderReviews(tableView: UITableView) {
        let options = GhostOptions(reuseIdentifier: ProductReviewTableViewCell.reuseIdentifier, rowsPerSection: Settings.placeholderRowsPerSection)
        tableView.displayGhostContent(options: options,
                                      style: .wooDefaultGhostStyle)

        data.stopForwardingEvents()
    }

    /// Removes Placeholder Notes (and restores the ResultsController <> UITableView link).
    ///
    func removePlaceholderReviews(tableView: UITableView) {
        tableView.removeGhostContent()
        data.startForwardingEvents(to: tableView)
    }

    func configureResultsController(tableView: UITableView) {
        data.startForwardingEvents(to: tableView)

        do {
            try data.observeReviews()
        } catch {
            CrashLogging.logError(error)
        }

        // Reload table because observeReviews() executes performFetch()
        tableView.reloadData()
    }

    func refreshResults() {
        data.refreshDataObservers()
    }

    /// Setup: TableViewCells
    ///
    func configureTableViewCells(tableView: UITableView) {
        tableView.registerNib(for: ProductReviewTableViewCell.self)
    }

    func containsMorePages(_ highestVisibleReview: Int) -> Bool {
        return highestVisibleReview > data.reviewCount
    }
}


// MARK: - Fetching data
extension ProductReviewsViewModel {

    /// Synchronizes the approved Reviews associated to the current store, for a specific Product ID.
    ///
    func synchronizeReviews(pageNumber: Int,
                            pageSize: Int,
                            productID: Int64,
                            onCompletion: (() -> Void)? = nil) {
        guard let siteID = ServiceLocator.stores.sessionManager.defaultStoreID else {
            return
        }

        let action = ProductReviewAction.synchronizeProductReviews(siteID: siteID,
                                                                   pageNumber: pageNumber,
                                                                   pageSize: pageSize,
                                                                   products: [productID],
                                                                   status: .approved) { error in
                                                                    if let error = error {
            DDLogError("⛔️ Error synchronizing reviews for product ID :\(productID). Error: \(error)")
                                                                        ServiceLocator.analytics.track(.productReviewListLoadFailed, withError: error)
                                                                    } else {
                                                                        ServiceLocator.analytics.track(.productReviewListLoaded)
                                                                    }

                                                                    onCompletion?()
        }

        ServiceLocator.stores.dispatch(action)
    }
}

private extension ProductReviewsViewModel {
    enum Settings {
        static let placeholderRowsPerSection = [3]
        static let firstPage = 1
        static let pageSize = 25
    }
}
