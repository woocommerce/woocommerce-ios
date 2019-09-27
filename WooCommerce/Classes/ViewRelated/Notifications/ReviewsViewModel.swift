import Foundation
import UIKit
import WordPressUI
import Yosemite


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
        tableView.displayGhostContent(options: options)

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
        try? data.observeReviews()
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
}


// MARK: - Fetching data
extension ReviewsViewModel {
    /// Prepares data necessary to render the reviews tab.
    ///
    func synchronizeReviews(onCompletion: (() -> Void)? = nil) {
        let group = DispatchGroup()

        group.enter()
        synchronizeAllReviews {
            print("===== reviews syncronized ===")
            group.leave()
        }

        group.enter()
        synchronizeProductsReviewed {
            print("===== products syncronized ===")
            group.leave()
        }

        group.enter()
        synchronizeNotifications {
            print("===== notifications syncronized ===")
            group.leave()
        }

        group.notify(queue: .main) {
            if let completionBlock = onCompletion {
                print("==== initiating render ===")
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
        let reviewsProductIDs = data.reviewsProductsIDs

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

    /// Synchronizes the Notifications associated to the active WordPress.com account.
    ///
    private func synchronizeNotifications(onCompletion: (() -> Void)? = nil) {
        let action = NotificationAction.synchronizeNotifications { error in
            if let error = error {
                DDLogError("⛔️ Error synchronizing notifications: \(error)")
            } else {
                ServiceLocator.analytics.track(.notificationListLoaded)
            }

            onCompletion?()
        }

        ServiceLocator.stores.dispatch(action)
    }
}

private extension ReviewsViewModel {
    /// Marks a specific Notification as read.
    ///
    func markAsReadIfNeeded(note: Note) {
        guard note.read == false else {
            return
        }

        let action = NotificationAction.updateReadStatus(noteId: note.noteId, read: true) { (error) in
            if let error = error {
                DDLogError("⛔️ Error marking single notification as read: \(error)")
            }
        }
        ServiceLocator.stores.dispatch(action)
    }

    /// Marks the specified collection of Notifications as Read.
    ///
    func markAsRead(notes: [Note], onCompletion: @escaping (Error?) -> Void) {
        let identifiers = notes.map { $0.noteId }
        let action = NotificationAction.updateMultipleReadStatus(noteIds: identifiers, read: true, onCompletion: onCompletion)

        ServiceLocator.stores.dispatch(action)
    }
}

private extension ReviewsViewModel {
    enum Settings {
        static let placeholderRowsPerSection = [3]
    }
}
