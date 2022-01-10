import Combine
import Foundation
import UIKit

import enum Yosemite.ProductReviewAction
import enum Yosemite.NotificationAction
import struct Yosemite.ProductReviewFromNoteParcel
import protocol Yosemite.StoresManager

/// Coordinator for the Reviews tab.
///
final class ReviewsCoordinator: Coordinator {
    var navigationController: UINavigationController

    private let pushNotificationsManager: PushNotesManager
    private let storesManager: StoresManager
    private let noticePresenter: NoticePresenter
    private let switchStoreUseCase: SwitchStoreUseCaseProtocol

    private var notificationsSubscription: AnyCancellable?

    private let willPresentReviewDetailsFromPushNotification: () -> Void

    init(navigationController: UINavigationController,
         pushNotificationsManager: PushNotesManager = ServiceLocator.pushNotesManager,
         storesManager: StoresManager = ServiceLocator.stores,
         noticePresenter: NoticePresenter = ServiceLocator.noticePresenter,
         switchStoreUseCase: SwitchStoreUseCaseProtocol,
         willPresentReviewDetailsFromPushNotification: @escaping () -> Void) {

        self.pushNotificationsManager = pushNotificationsManager
        self.storesManager = storesManager
        self.noticePresenter = noticePresenter
        self.switchStoreUseCase = switchStoreUseCase
        self.willPresentReviewDetailsFromPushNotification = willPresentReviewDetailsFromPushNotification
        self.navigationController = navigationController
    }

    convenience init(navigationController: UINavigationController, willPresentReviewDetailsFromPushNotification: @escaping () -> Void) {
        let storesManager = ServiceLocator.stores
        self.init(navigationController: navigationController,
                  storesManager: storesManager,
                  switchStoreUseCase: SwitchStoreUseCase(stores: storesManager),
                  willPresentReviewDetailsFromPushNotification: willPresentReviewDetailsFromPushNotification)
    }

    deinit {
        notificationsSubscription?.cancel()
    }

    func start() {
        // No-op: please call `activate(siteID:)` instead when the reviews tab is configured.
    }

    /// Replaces `start()` because the reviews tab's navigation stack could be updated multiple times when site ID changes.
    func activate(siteID: Int64) {
        navigationController.viewControllers = [ReviewsViewController(siteID: siteID)]

        if notificationsSubscription == nil {
            notificationsSubscription = Publishers
                .Merge(pushNotificationsManager.inactiveNotifications, pushNotificationsManager.foregroundNotificationsToView)
                .sink { [weak self] in
                self?.handleNotification($0)
            }
        }
    }

    private func handleNotification(_ notification: PushNotification) {
        guard notification.kind == .comment else {
            return
        }

        let action = ProductReviewAction.retrieveProductReviewFromNote(noteID: Int64(notification.noteID)) { [weak self] result in
            guard let self = self else {
                return
            }

            switch result {
            case .failure:
                self.noticePresenter.enqueue(notice: Notice(title: Localization.failedToRetrieveNotificationDetails))
            case .success(let parcel):
                guard let siteID = parcel.note.meta.identifier(forKey: .site) else {
                    self.noticePresenter.enqueue(notice: Notice(title: Localization.failedToRetrieveNotificationDetails))
                    return
                }

                // Switch to the correct store first if needed
                self.switchStoreUseCase.switchStore(with: Int64(siteID)) { [weak self] siteChanged in
                    guard let self = self else {
                        return
                    }

                    self.willPresentReviewDetailsFromPushNotification()
                    self.pushReviewDetailsViewController(using: parcel)

                    if siteChanged {
                        let presenter = SwitchStoreNoticePresenter(siteID: Int64(siteID),
                                                                   noticePresenter: self.noticePresenter)
                        presenter.presentStoreSwitchedNoticeWhenSiteIsAvailable(configuration: .switchingStores)
                    }
                }
            }
        }

        storesManager.dispatch(action)
    }

    private func pushReviewDetailsViewController(using parcel: ProductReviewFromNoteParcel) {
        let detailsVC = ReviewDetailsViewController(productReview: parcel.review,
                                                    product: parcel.product,
                                                    notification: parcel.note)
        navigationController.pushViewController(detailsVC, animated: true)
    }
}

// MARK: - Public Utils

extension ReviewsCoordinator {
    enum Localization {
        static let failedToRetrieveNotificationDetails =
            NSLocalizedString("Failed to retrieve the review notification details.",
                              comment: "An error message shown when failing to retrieve information to present a view for a review push notification.")
    }
}
