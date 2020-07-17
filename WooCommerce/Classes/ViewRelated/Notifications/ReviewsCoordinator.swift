
import Foundation
import UIKit
import enum Yosemite.ProductReviewAction

/// Coordinator for the Reviews tab.
///
final class ReviewsCoordinator: Coordinator {
    var navigationController: UINavigationController

    private let pushNotificationsManager: PushNotesManager
    private let storesManager: StoresManager
    private let noticePresenter: NoticePresenter

    private var observationToken: ObservationToken?

    init(pushNotificationsManager: PushNotesManager = ServiceLocator.pushNotesManager,
         storesManager: StoresManager = ServiceLocator.stores,
         noticePresenter: NoticePresenter = ServiceLocator.noticePresenter) {

        self.pushNotificationsManager = pushNotificationsManager
        self.storesManager = storesManager
        self.noticePresenter = noticePresenter

        self.navigationController = WooNavigationController(rootViewController: ReviewsViewController())
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
                let detailsVC = ReviewDetailsViewController(productReview: parcel.review,
                                                            product: parcel.product,
                                                            notification: parcel.note)
                self.navigationController.pushViewController(detailsVC, animated: true)
            }
        }

        storesManager.dispatch(action)
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
