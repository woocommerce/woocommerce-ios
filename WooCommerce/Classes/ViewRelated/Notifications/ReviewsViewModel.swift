import Foundation
import UIKit
import WordPressUI
import Yosemite


final class ReviewsViewModel {
    private let data = ReviewsDataSource()

    var isEmpty: Bool {
        return data.resultsController.isEmpty
    }

    var dataSource: UITableViewDataSource {
        return data
    }

    var delegate: UITableViewDelegate {
        return data
    }

    func displayPlaceholderReviews(tableView: UITableView) {
        let options = GhostOptions(reuseIdentifier: NoteTableViewCell.reuseIdentifier, rowsPerSection: Settings.placeholderRowsPerSection)
        tableView.displayGhostContent(options: options)

        data.resultsController.stopForwardingEvents()
    }

    /// Removes Placeholder Notes (and restores the ResultsController <> UITableView link).
    ///
    func removePlaceholderReviews(tableView: UITableView) {
        tableView.removeGhostContent()
        data.resultsController.startForwardingEvents(to: tableView)
    }

    func configureResultsController(tableView: UITableView) {
        data.resultsController.startForwardingEvents(to: tableView)
        try? data.resultsController.performFetch()
    }

    /// Setup: TableViewCells
    ///
    func configureTableViewCells(tableView: UITableView) {
        let cells = [NoteTableViewCell.self]

        for cell in cells {
            tableView.register(cell.loadNib(), forCellReuseIdentifier: cell.reuseIdentifier)
        }
    }
}


extension ReviewsViewModel {
    /// Synchronizes the Reviews associated to the current store.
    ///
    func synchronizeReviews(onCompletion: (() -> Void)? = nil) {
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
}

private extension ReviewsViewModel {
    enum Settings {
        static let placeholderRowsPerSection = [3]
    }
}
