import Combine
import Foundation
import UIKit

import enum Yosemite.ProductReviewAction
import struct Yosemite.ProductReviewFromNoteParcel
import protocol Yosemite.StoresManager

/// Coordinator for the HubMenu tab.
///
final class HubMenuCoordinator {
    let tabContainerController: TabContainerController
    var hubMenuController: HubMenuViewController?

    private let pushNotificationsManager: PushNotesManager
    private let storesManager: StoresManager
    private let noticePresenter: NoticePresenter
    private let httpsConfigurationWarningViewModel: HTTPSConfigurationWarningViewModel

    private var notificationsSubscription: AnyCancellable?

    private let beginNavigation: () -> (() -> Bool)?
    private let showReview: (ProductReviewFromNoteParcel) -> Void

    private let tapToPayBadgePromotionChecker: TapToPayBadgePromotionChecker

    init(tabContainerController: TabContainerController,
         pushNotificationsManager: PushNotesManager = ServiceLocator.pushNotesManager,
         storesManager: StoresManager = ServiceLocator.stores,
         noticePresenter: NoticePresenter = ServiceLocator.noticePresenter,
         httpsConfigurationWarningViewModel: HTTPSConfigurationWarningViewModel,
         tapToPayBadgePromotionChecker: TapToPayBadgePromotionChecker,
         beginNavigation: @escaping () -> (() -> Bool)?,
         showReview: @escaping (ProductReviewFromNoteParcel) -> Void) {

        self.pushNotificationsManager = pushNotificationsManager
        self.storesManager = storesManager
        self.noticePresenter = noticePresenter
        self.httpsConfigurationWarningViewModel = httpsConfigurationWarningViewModel
        self.tapToPayBadgePromotionChecker = tapToPayBadgePromotionChecker
        self.beginNavigation = beginNavigation
        self.showReview = showReview
        self.tabContainerController = tabContainerController
    }

    deinit {
        notificationsSubscription?.cancel()
    }

    /// Used to reload the Hub menu screen when selected site changes
    ///
    @MainActor
    func activate(siteID: Int64) {
        hubMenuController = HubMenuViewController(siteID: siteID,
                                                  stores: storesManager,
                                                  httpsConfigurationWarningViewModel: httpsConfigurationWarningViewModel,
                                                  tapToPayBadgePromotionChecker: tapToPayBadgePromotionChecker)
        if let hubMenuController {
            let navigationController = UINavigationController(rootViewController: hubMenuController)
            tabContainerController.wrappedController = navigationController
        }

        if notificationsSubscription == nil {
            notificationsSubscription = Publishers
                .Merge(pushNotificationsManager.inactiveNotifications, pushNotificationsManager.foregroundNotificationsToView)
                .sink { [weak self] in
                    self?.handleNotification($0)
                }
        }
    }

    @MainActor
    private func handleNotification(_ notification: WooCommerce.PushNotification) {
        guard notification.kind == .comment, let isCurrent = beginNavigation() else { return }

        let completion: (Result<ProductReviewFromNoteParcel, Error>) -> Void = { [weak self] result in
            guard let self, isCurrent() else { return }
            switch result {
            case .failure:
                noticePresenter.enqueue(notice: Notice(title: Localization.failedToRetrieveReviewNotificationDetails))
            case .success(let review):
                showReview(review)
            }
        }
        if let noteID = notification.noteID {
            storesManager.dispatch(ProductReviewAction.retrieveProductReviewFromNote(noteID: Int64(noteID), onCompletion: completion))
        } else if let reviewID = notification.meta?.identifier(forKey: .comment) {
            storesManager.dispatch(ProductReviewAction.retrieveProductReviewAndProduct(
                siteID: notification.resolvedSiteID(stores: storesManager),
                reviewID: Int64(reviewID),
                onCompletion: completion))
        }
    }
}

// MARK: - Deeplinks
extension HubMenuCoordinator: DeepLinkNavigator {
    func navigate(to destination: any DeepLinkDestinationProtocol) {
        guard let hubMenuController else {
            return
        }
        hubMenuController.navigate(to: destination)
    }
}

// MARK: - Constants
private extension HubMenuCoordinator {
    enum Constants {
        // Used to delay a second navigation after the previous one is called,
        // to ensure that the first transition is finished. Without this delay
        // the second one might not happen.
        static let screenTransitionsDelay = 0.3
    }
}
// MARK: - Public Utils

extension HubMenuCoordinator {
    enum Localization {
        static let failedToRetrieveReviewNotificationDetails =
            NSLocalizedString("Failed to retrieve the review notification details.",
                              comment: "An error message shown when failing to retrieve information to present a view for a review push notification.")
    }
}
