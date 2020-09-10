import Foundation
import UIKit

import enum Yosemite.ProductReviewAction
import enum Yosemite.NotificationAction
import struct Yosemite.ProductReviewFromNoteParcel

/// Coordinator for the Reviews tab.
///
final class ReviewsCoordinator: Coordinator {
    var navigationController: UINavigationController

    private let pushNotificationsManager: PushNotesManager
    private let storesManager: StoresManager
    private let noticePresenter: NoticePresenter
    private let switchStoreUseCase: SwitchStoreUseCaseProtocol

    private var observationToken: ObservationToken?

    private let willPresentReviewDetailsFromPushNotification: () -> Void

    init(pushNotificationsManager: PushNotesManager = ServiceLocator.pushNotesManager,
         storesManager: StoresManager = ServiceLocator.stores,
         noticePresenter: NoticePresenter = ServiceLocator.noticePresenter,
         switchStoreUseCase: SwitchStoreUseCaseProtocol,
         willPresentReviewDetailsFromPushNotification: @escaping () -> Void) {

        self.pushNotificationsManager = pushNotificationsManager
        self.storesManager = storesManager
        self.noticePresenter = noticePresenter
        self.switchStoreUseCase = switchStoreUseCase
        self.willPresentReviewDetailsFromPushNotification = willPresentReviewDetailsFromPushNotification

        self.navigationController = WooNavigationController(rootViewController: ReviewsViewController())
    }

    convenience init(willPresentReviewDetailsFromPushNotification: @escaping () -> Void) {
        let storesManager = ServiceLocator.stores
        self.init(storesManager: storesManager,
                  switchStoreUseCase: SwitchStoreUseCase(stores: storesManager),
                  willPresentReviewDetailsFromPushNotification: willPresentReviewDetailsFromPushNotification)
    }

    deinit {
        observationToken?.cancel()
    }

    func start() {
        observationToken = pushNotificationsManager.inactiveNotifications.subscribe { [weak self] in
            self?.handleInactiveNotification($0)
        }
    }

    private func handleInactiveNotification(_ notification: PushNotification) {
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
                        let presenter = SwitchStoreNoticePresenter(sessionManager: self.storesManager.sessionManager,
                                                                   noticePresenter: self.noticePresenter)
                        presenter.presentStoreSwitchedNotice(configuration: .switchingStores)
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
