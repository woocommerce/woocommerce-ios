import Foundation
import UIKit
import WordPressUI
import Yosemite


final class ReviewsViewModel {
    private let data: ReviewsDataSource

    var isEmpty: Bool {
        return data.reviewsResultsController.isEmpty
    }

    var dataSource: UITableViewDataSource {
        return data
    }

    var delegate: UITableViewDelegate {
        return data
    }

    init(data: ReviewsDataSource) {
        self.data = data
    }

    func displayPlaceholderReviews(tableView: UITableView) {
        let options = GhostOptions(reuseIdentifier: ProductReviewTableViewCell.reuseIdentifier, rowsPerSection: Settings.placeholderRowsPerSection)
        tableView.displayGhostContent(options: options)

        data.reviewsResultsController.stopForwardingEvents()
    }

    /// Removes Placeholder Notes (and restores the ResultsController <> UITableView link).
    ///
    func removePlaceholderReviews(tableView: UITableView) {
        tableView.removeGhostContent()
        data.reviewsResultsController.startForwardingEvents(to: tableView)
    }

    func configureResultsController(tableView: UITableView) {
        data.reviewsResultsController.startForwardingEvents(to: tableView)
        try? data.reviewsResultsController.performFetch()
    }

    /// Setup: TableViewCells
    ///
    func configureTableViewCells(tableView: UITableView) {
        let cells = [ProductReviewTableViewCell.self]

        for cell in cells {
            tableView.register(cell.loadNib(), forCellReuseIdentifier: cell.reuseIdentifier)
        }
    }
}


// MARK: - Fetching data
extension ReviewsViewModel {
    /// Prepares data necessary to render the reviews tab.
    ///
    func synchronizeReviews(onCompletion: (() -> Void)? = nil) {
        let group = DispatchGroup()

        group.enter()
        synchronizeAllReviews {
            group.leave()
        }

        group.enter()
        synchronizeProductsReviewed {
            group.leave()
        }

        group.notify(queue: .main) {
            if let completionBlock = onCompletion {
                completionBlock()
            }
        }
    }

    /// Synchronizes the Reviews associated to the current store.
    ///
    private func synchronizeAllReviews(onCompletion: (() -> Void)? = nil) {
        guard let siteID = ServiceLocator.stores.sessionManager.defaultStoreID else {
            return
        }

        let action = ProductReviewAction.synchronizeProductReviews(siteID: siteID, pageNumber: 1, pageSize: 25) { error in
            if let error = error {
                DDLogError("⛔️ Error synchronizing reviews: \(error)")
            } else {
                //TODO. What event must be sent here?
                //ServiceLocator.analytics.track(.notificationListLoaded)
            }

            onCompletion?()
        }

        ServiceLocator.stores.dispatch(action)
    }

    private func synchronizeProductsReviewed(onCompletion: @escaping () -> Void) {
        let reviews = data.reviewsResultsController.fetchedObjects
        let reviewsProductIDs = reviews.map { return $0.productID }.uniqued()

        guard let siteID = ServiceLocator.stores.sessionManager.defaultStoreID else {
            return
        }

        let action = ProductAction.retrieveProducts(siteID: siteID, productIDs: reviewsProductIDs) { error in
            if let error = error {
                DDLogError("⛔️ Error synchronizing products: \(error)")
            } else {
                //TODO. What event must be sent here?
                //ServiceLocator.analytics.track(.notificationListLoaded)
            }

            onCompletion()
        }

        ServiceLocator.stores.dispatch(action)
    }
}

private extension ReviewsViewModel {
    enum Settings {
        static let placeholderRowsPerSection = [3]
    }
}
