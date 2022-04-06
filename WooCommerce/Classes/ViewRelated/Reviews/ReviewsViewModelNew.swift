import Foundation
import UIKit
import WordPressUI
import Yosemite

import class AutomatticTracks.CrashLogging


/// Provides data and handles actions of Reviews screen.
/// Used as view model for `ReviewsViewController`
///
final class ReviewsViewModelNew {
    private let siteID: Int64

    let data: ReviewsDataSource
    private let stores: StoresManager

    var isEmpty: Bool {
        return data.isEmpty
    }

    var dataSource: UITableViewDataSource {
        return data
    }

    var delegate: ReviewsInteractionDelegate {
        return data
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
    var hasErrorLoadingData: Bool = false

    init(siteID: Int64, data: ReviewsDataSource, stores: StoresManager = ServiceLocator.stores, reviewsSynchronizer: ReviewsSynchronizer) {
        self.siteID = siteID
        self.data = data
        self.stores = stores
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

    func synchronizeReviews(pageNumber: Int,
                            pageSize: Int,
                            onCompletion: (() -> Void)?) {

    }
}


protocol ReviewsSynchronizer {
    func synchronizeReviews(pageNumber: Int,
                            pageSize: Int,
                            onCompletion: (() -> Void)?,
                            onError: (() -> ()))
}

// MARK: - Fetching data
//extension ReviewsViewModelNew {
//    /// Prepares data necessary to render the reviews tab.
//    ///
//    func synchronizeReviews(pageNumber: Int,
//                            pageSize: Int,
//                            onCompletion: (() -> Void)?) {
//        hasErrorLoadingData = false
//
//        let group = DispatchGroup()
//
//        group.enter()
//        synchronizeAllReviews(pageNumber: pageNumber, pageSize: pageSize) { [weak self] reviews in
//            let productIDs = reviews.map { $0.productID }.uniqued()
//            self?.synchronizeProductsReviewed(reviewsProductIDs: productIDs) {
//                group.leave()
//            }
//        }
//
//        group.enter()
//        synchronizeNotifications {
//            group.leave()
//        }
//
//        group.notify(queue: .main) {
//            onCompletion?()
//        }
//    }
//
//    /// Synchronizes the Reviews associated to the current store.
//    ///
//    private func synchronizeAllReviews(pageNumber: Int,
//                                       pageSize: Int,
//                                       onCompletion: (([ProductReview]) -> Void)? = nil) {
//        let action = ProductReviewAction.synchronizeProductReviews(siteID: siteID,
//                                                                   pageNumber: pageNumber,
//                                                                   pageSize: pageSize) { [weak self] result in
//            switch result {
//            case .failure(let error):
//                DDLogError("⛔️ Error synchronizing reviews: \(error)")
//                ServiceLocator.analytics.track(.reviewsListLoadFailed,
//                                               withError: error)
//                self?.hasErrorLoadingData = true
//                onCompletion?([])
//            case .success(let reviews):
//                let loadingMore = pageNumber != Settings.firstPage
//                ServiceLocator.analytics.track(.reviewsListLoaded,
//                                               withProperties: ["is_loading_more": loadingMore])
//                onCompletion?(reviews)
//            }
//        }
//
//        stores.dispatch(action)
//    }
//
//    private func synchronizeProductsReviewed(reviewsProductIDs: [Int64], onCompletion: @escaping () -> Void) {
//        let action = ProductAction.retrieveProducts(siteID: siteID, productIDs: reviewsProductIDs) { [weak self] result in
//            switch result {
//            case .failure(let error):
//                DDLogError("⛔️ Error synchronizing products: \(error)")
//                ServiceLocator.analytics.track(.reviewsProductsLoadFailed,
//                                               withError: error)
//                self?.hasErrorLoadingData = true
//            case .success:
//                ServiceLocator.analytics.track(.reviewsProductsLoaded)
//            }
//
//            onCompletion()
//        }
//
//        stores.dispatch(action)
//    }
//
//    /// Synchronizes the Notifications associated to the active WordPress.com account.
//    ///
//    private func synchronizeNotifications(onCompletion: (() -> Void)? = nil) {
//        let action = NotificationAction.synchronizeNotifications { [weak self] error in
//            if let error = error {
//                DDLogError("⛔️ Error synchronizing notifications: \(error)")
//                ServiceLocator.analytics.track(.notificationsLoadFailed,
//                                               withError: error)
//                self?.hasErrorLoadingData = true
//            } else {
//                ServiceLocator.analytics.track(.notificationListLoaded)
//            }
//
//            onCompletion?()
//        }
//
//        stores.dispatch(action)
//    }
//}

private extension ReviewsViewModelNew {
    /// Marks the specified collection of Notifications as Read.
    ///
    func markAsRead(notes: [Note], onCompletion: @escaping (Error?) -> Void) {
        let identifiers = notes.map { $0.noteID }
        let action = NotificationAction.updateMultipleReadStatus(noteIDs: identifiers, read: true, onCompletion: onCompletion)

        stores.dispatch(action)
    }
}

private extension ReviewsViewModelNew {
    enum Settings {
        static let firstPage = 1
        static let pageSize = 25
    }

    struct Constants {
        static let section = "notifications"
    }
}

final class SiteReviewsSynchronizer: ReviewsSynchronizer {
    private let stores: StoresManager
    private let siteID: Int64

    init(siteID: Int64, stores: StoresManager = ServiceLocator.stores) {
        self.siteID = siteID
        self.stores = stores
    }

    func synchronizeReviews(pageNumber: Int,
                            pageSize: Int,
                            onCompletion: (() -> Void)?,
                            onError: (() -> ())) {
        let group = DispatchGroup()

        group.enter()
        synchronizeAllReviews(pageNumber: pageNumber, pageSize: pageSize) { [weak self] reviews in
            let productIDs = reviews.map { $0.productID }.uniqued()
            self?.synchronizeProductsReviewed(reviewsProductIDs: productIDs) {
                group.leave()
            }
        }

        group.enter()
        synchronizeNotifications {
            group.leave()
        }

        group.notify(queue: .main) {
            onCompletion?()
        }
    }

    /// Synchronizes the Reviews associated to the current store.
    ///
    private func synchronizeAllReviews(pageNumber: Int,
                                       pageSize: Int,
                                       onCompletion: (([ProductReview]) -> Void)? = nil,
                                       onError: (() -> ())) {
        let action = ProductReviewAction.synchronizeProductReviews(siteID: siteID,
                                                                   pageNumber: pageNumber,
                                                                   pageSize: pageSize) { result in
            switch result {
            case .failure(let error):
                DDLogError("⛔️ Error synchronizing reviews: \(error)")
                ServiceLocator.analytics.track(.reviewsListLoadFailed,
                                               withError: error)
                onError()
                onCompletion?([])
            case .success(let reviews):
                let loadingMore = pageNumber != 1
                ServiceLocator.analytics.track(.reviewsListLoaded,
                                               withProperties: ["is_loading_more": loadingMore])
                onCompletion?(reviews)
            }
        }

        stores.dispatch(action)
    }

    private func synchronizeProductsReviewed(reviewsProductIDs: [Int64],
                                             onCompletion: @escaping () -> Void,
                                             onError: (() -> ())) {
        let action = ProductAction.retrieveProducts(siteID: siteID, productIDs: reviewsProductIDs) { result in
            switch result {
            case .failure(let error):
                DDLogError("⛔️ Error synchronizing products: \(error)")
                ServiceLocator.analytics.track(.reviewsProductsLoadFailed,
                                               withError: error)
                onError()
            case .success:
                ServiceLocator.analytics.track(.reviewsProductsLoaded)
            }

            onCompletion()
        }

        stores.dispatch(action)
    }

    /// Synchronizes the Notifications associated to the active WordPress.com account.
    ///
    private func synchronizeNotifications(onCompletion: (() -> Void)? = nil, onError: (() -> ())) {
        let action = NotificationAction.synchronizeNotifications { error in
            if let error = error {
                DDLogError("⛔️ Error synchronizing notifications: \(error)")
                ServiceLocator.analytics.track(.notificationsLoadFailed,
                                               withError: error)
                onError()
            } else {
                ServiceLocator.analytics.track(.notificationListLoaded)
            }

            onCompletion?()
        }

        stores.dispatch(action)
    }
}
