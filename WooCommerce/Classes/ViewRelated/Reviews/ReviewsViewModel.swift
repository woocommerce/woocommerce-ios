import Foundation
import UIKit
import WordPressUI
import Yosemite

import class AutomatticTracks.CrashLogging

/// Provides data for the Reviews screen
///
protocol ReviewsViewModelOutput {
    var isEmpty: Bool { get }

    var dataSource: UITableViewDataSource { get }

    var delegate: ReviewsInteractionDelegate { get }

    var hasUnreadNotifications: Bool { get }

    var shouldPromptForAppReview: Bool { get }

    var dataLoadingError: Error? { get set }

    func containsMorePages(_ highestVisibleReview: Int) -> Bool
}

/// Handles actions related to Reviews screen
///
protocol ReviewsViewModelActionsHandler {
    func configureResultsController(tableView: UITableView)

    func refreshResults()

    func configureTableViewCells(tableView: UITableView)

    func markAllAsRead(onCompletion: @escaping (Error?) -> Void)

    func synchronizeReviews(pageNumber: Int,
                            pageSize: Int,
                            onCompletion: (() -> Void)?)
}

/// Provides data and handles actions of Reviews screen.
/// Used as view model for `ReviewsViewController`
///
final class ReviewsViewModel: ReviewsViewModelOutput, ReviewsViewModelActionsHandler {
    private let siteID: Int64

    private let data: ReviewsDataSourceProtocol
    private let stores: StoresManager
    private let pushNotesManager: PushNotesManager

    var isEmpty: Bool {
        return data.isEmpty
    }

    var dataSource: UITableViewDataSource {
        return data
    }

    var delegate: ReviewsInteractionDelegate {
        return data
    }

    /// Whether notifications-based features (unread indicators, mark as read) should be available.
    /// Returns false for sites using Woo-driven push notifications since they don't have WPCom notifications.
    var supportsWPComNotifications: Bool {
        // Skip if authenticated without WPCom (no notifications available)
        guard stores.isAuthenticatedWithoutWPCom == false else {
            return false
        }
        // Skip if site is registered for Woo-driven push notifications (WPCom notifications not used)
        guard pushNotesManager.siteIDsRegisteredForWooPNs.contains(siteID) == false else {
            return false
        }
        return true
    }

    var hasUnreadNotifications: Bool {
        guard supportsWPComNotifications else {
            return false
        }
        return !unreadNotifications.isEmpty
    }

    private var unreadNotifications: [Note] {
        return data.notifications.filter { $0.read == false }
    }

    /// Used to check whether the user should be prompted for an app from `ReviewsViewController`
    ///
    var shouldPromptForAppReview: Bool {
        AppRatingManager.shared.shouldPromptForAppReview(section: Constants.section)
    }

    /// Set when sync fails, and used to display an error loading data banner
    ///
    var dataLoadingError: Error?

    init(siteID: Int64,
         data: ReviewsDataSourceProtocol,
         stores: StoresManager = ServiceLocator.stores,
         pushNotesManager: PushNotesManager = ServiceLocator.pushNotesManager) {
        self.siteID = siteID
        self.data = data
        self.stores = stores
        self.pushNotesManager = pushNotesManager
    }

    func configureResultsController(tableView: UITableView) {
        data.startForwardingEvents(to: tableView)

        do {
            try data.observeReviews()
        } catch {
            ServiceLocator.crashLogging.logError(error)
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
    func synchronizeReviews(pageNumber: Int,
                            pageSize: Int,
                            onCompletion: (() -> Void)?) {
        dataLoadingError = nil

        let group = DispatchGroup()

        group.enter()
        synchronizeAllReviews(pageNumber: pageNumber, pageSize: pageSize) { [weak self] reviews in
            let productIDs = reviews.map { $0.productID }.uniqued()
            self?.synchronizeProductsReviewed(reviewsProductIDs: productIDs) {
                group.leave()
            }
        }

        // Skip syncing notifications if WPCom notifications are not available
        // (authenticated without WPCom or site uses Woo-driven push notifications).
        if supportsWPComNotifications {
            group.enter()
            synchronizeNotifications {
                group.leave()
            }
        }

        group.notify(queue: .main) {
            onCompletion?()
        }
    }

    /// Synchronizes the Reviews associated to the current store.
    ///
    private func synchronizeAllReviews(pageNumber: Int,
                                       pageSize: Int,
                                       onCompletion: (([ProductReview]) -> Void)? = nil) {
        let action = ProductReviewAction.synchronizeProductReviews(siteID: siteID, pageNumber: pageNumber, pageSize: pageSize) { [weak self] result in
            switch result {
            case .failure(let error):
                DDLogError("⛔️ Error synchronizing reviews: \(error)")
                ServiceLocator.analytics.track(.reviewsListLoadFailed,
                                               withError: error)
                self?.dataLoadingError = error
                onCompletion?([])
            case .success(let reviews):
                let loadingMore = pageNumber != Settings.firstPage
                ServiceLocator.analytics.track(.reviewsListLoaded,
                                               withProperties: ["is_loading_more": loadingMore])
                onCompletion?(reviews)
            }
        }

        stores.dispatch(action)
    }

    private func synchronizeProductsReviewed(reviewsProductIDs: [Int64], onCompletion: @escaping () -> Void) {
        let action = ProductAction.retrieveProducts(siteID: siteID, productIDs: reviewsProductIDs) { [weak self] result in
            switch result {
            case .failure(let error):
                DDLogError("⛔️ Error synchronizing products: \(error)")
                ServiceLocator.analytics.track(.reviewsProductsLoadFailed,
                                               withError: error)
                self?.dataLoadingError = error
            case .success:
                ServiceLocator.analytics.track(.reviewsProductsLoaded)
            }

            onCompletion()
        }

        stores.dispatch(action)
    }

    /// Synchronizes the Notifications associated to the active WordPress.com account.
    ///
    private func synchronizeNotifications(onCompletion: (() -> Void)? = nil) {
        let action = NotificationAction.synchronizeNotifications { [weak self] error in
            if let error = error {
                DDLogError("⛔️ Error synchronizing notifications: \(error)")
                ServiceLocator.analytics.track(.notificationsLoadFailed,
                                               withError: error)
                self?.dataLoadingError = error
            } else {
                ServiceLocator.analytics.track(.notificationListLoaded)
            }

            onCompletion?()
        }

        stores.dispatch(action)
    }
}

private extension ReviewsViewModel {
    /// Marks the specified collection of Notifications as Read.
    ///
    func markAsRead(notes: [Note], onCompletion: @escaping (Error?) -> Void) {
        let identifiers = notes.compactMap { $0.noteID }
        let action = NotificationAction.updateMultipleReadStatus(noteIDs: identifiers, read: true, onCompletion: onCompletion)

        stores.dispatch(action)
    }
}

private extension ReviewsViewModel {
    enum Settings {
        static let firstPage = 1
        static let pageSize = 25
    }

    struct Constants {
        static let section = "notifications"
    }
}

/// Customizes the `ReviewsDataSource` for a global reviews query (all of a site)
final class GlobalReviewsDataSourceCustomizer: ReviewsDataSourceCustomizing {
    let shouldShowProductTitleOnCells = true

    func reviewsFilterPredicate(with sitePredicate: NSPredicate) -> NSPredicate {
        let statusPredicate = NSPredicate(format: "statusKey ==[c] %@ OR statusKey ==[c] %@",
                                          ProductReviewStatus.approved.rawValue,
                                          ProductReviewStatus.hold.rawValue)

        return  NSCompoundPredicate(andPredicateWithSubpredicates: [sitePredicate, statusPredicate])

    }
}
