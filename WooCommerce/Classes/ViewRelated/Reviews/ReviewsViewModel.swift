import Foundation
import UIKit
import WordPressUI
import Yosemite

import class AutomatticTracks.CrashLogging


final class ReviewsViewModel {
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

    var hasUnreadNotifications: Bool {
        return unreadNotifications.count != 0
    }

    private var unreadNotifications: [Note] {
        return data.notifications.filter { $0.read == false }
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
        tableView.reloadData()
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
        let cells = [ProductReviewTableViewCell.self]

        for cell in cells {
            tableView.register(cell.loadNib(), forCellReuseIdentifier: cell.reuseIdentifier)
        }
    }

    func markAllAsRead(onCompletion: @escaping (Error?) -> Void) {
        markAsRead(notes: unreadNotifications, onCompletion: onCompletion)
    }

    func containsMorePages(_ highestVisibleReview: Int) -> Bool {
        return highestVisibleReview > data.reviewCount
    }
}


// MARK: - Fetching data
extension ReviewsViewModel {
    /// Prepares data necessary to render the reviews tab.
    ///
    func synchronizeReviews(pageNumber: Int = Settings.firstPage,
                            pageSize: Int = Settings.pageSize,
                            onCompletion: (() -> Void)? = nil) {
        let group = DispatchGroup()

        group.enter()
        synchronizeAllReviews(pageNumber: pageNumber, pageSize: pageSize) {
            group.leave()
        }

        group.enter()
        synchronizeProductsReviewed {
            group.leave()
        }

        group.enter()
        synchronizeNotifications {
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
    private func synchronizeAllReviews(pageNumber: Int,
                                       pageSize: Int,
                                       onCompletion: (() -> Void)? = nil) {
        guard let siteID = ServiceLocator.stores.sessionManager.defaultStoreID else {
            return
        }

        let action = ProductReviewAction.synchronizeProductReviews(siteID: siteID, pageNumber: pageNumber, pageSize: pageSize) { error in
            if let error = error {
                DDLogError("⛔️ Error synchronizing reviews: \(error)")
                ServiceLocator.analytics.track(.reviewsListLoadFailed,
                                               withError: error)
            } else {
                let loadingMore = pageNumber != Settings.firstPage
                ServiceLocator.analytics.track(.reviewsListLoaded,
                                               withProperties: ["is_loading_more": loadingMore])
            }

            onCompletion?()
        }

        ServiceLocator.stores.dispatch(action)
    }

    private func synchronizeProductsReviewed(onCompletion: @escaping () -> Void) {
        let reviewsProductIDs = data.reviewsProductsIDs

        guard let siteID = ServiceLocator.stores.sessionManager.defaultStoreID else {
            return
        }

        let action = ProductAction.retrieveProducts(siteID: siteID, productIDs: reviewsProductIDs) { result in
            switch result {
            case .failure(let error):
                DDLogError("⛔️ Error synchronizing products: \(error)")
                ServiceLocator.analytics.track(.reviewsProductsLoadFailed,
                                               withError: error)
            case .success:
                ServiceLocator.analytics.track(.reviewsProductsLoaded)
            }

            onCompletion()
        }

        ServiceLocator.stores.dispatch(action)
    }

    /// Synchronizes the Notifications associated to the active WordPress.com account.
    ///
    private func synchronizeNotifications(onCompletion: (() -> Void)? = nil) {
        let action = NotificationAction.synchronizeNotifications { error in
            if let error = error {
                DDLogError("⛔️ Error synchronizing notifications: \(error)")
                ServiceLocator.analytics.track(.notificationsLoadFailed,
                                               withError: error)
            } else {
                ServiceLocator.analytics.track(.notificationListLoaded)
            }

            onCompletion?()
        }

        ServiceLocator.stores.dispatch(action)
    }
}

private extension ReviewsViewModel {
    /// Marks the specified collection of Notifications as Read.
    ///
    func markAsRead(notes: [Note], onCompletion: @escaping (Error?) -> Void) {
        let identifiers = notes.map { $0.noteID }
        let action = NotificationAction.updateMultipleReadStatus(noteIDs: identifiers, read: true, onCompletion: onCompletion)

        ServiceLocator.stores.dispatch(action)
    }
}

private extension ReviewsViewModel {
    enum Settings {
        static let placeholderRowsPerSection = [3]
        static let firstPage = 1
        static let pageSize = 25
    }
}
