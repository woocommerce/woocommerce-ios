import Combine
import Foundation
import UIKit

import enum Yosemite.ProductReviewAction
import enum Yosemite.NotificationAction
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
    private let switchStoreUseCase: SwitchStoreUseCaseProtocol

    private var notificationsSubscription: AnyCancellable?

    private let willPresentReviewDetailsFromPushNotification: () async -> Void

    private let tapToPayBadgePromotionChecker: TapToPayBadgePromotionChecker

    init(tabContainerController: TabContainerController,
         pushNotificationsManager: PushNotesManager = ServiceLocator.pushNotesManager,
         storesManager: StoresManager = ServiceLocator.stores,
         noticePresenter: NoticePresenter = ServiceLocator.noticePresenter,
         switchStoreUseCase: SwitchStoreUseCaseProtocol,
         tapToPayBadgePromotionChecker: TapToPayBadgePromotionChecker,
         willPresentReviewDetailsFromPushNotification: @escaping () async -> Void) {

        self.pushNotificationsManager = pushNotificationsManager
        self.storesManager = storesManager
        self.noticePresenter = noticePresenter
        self.switchStoreUseCase = switchStoreUseCase
        self.tapToPayBadgePromotionChecker = tapToPayBadgePromotionChecker
        self.willPresentReviewDetailsFromPushNotification = willPresentReviewDetailsFromPushNotification
        self.tabContainerController = tabContainerController
    }

    convenience init(tabContainerController: TabContainerController,
                     storesManager: StoresManager = ServiceLocator.stores,
                     tapToPayBadgePromotionChecker: TapToPayBadgePromotionChecker,
                     willPresentReviewDetailsFromPushNotification: @escaping () async -> Void) {
        self.init(tabContainerController: tabContainerController,
                  storesManager: storesManager,
                  switchStoreUseCase: SwitchStoreUseCase(stores: storesManager),
                  tapToPayBadgePromotionChecker: tapToPayBadgePromotionChecker,
                  willPresentReviewDetailsFromPushNotification: willPresentReviewDetailsFromPushNotification)
    }

    deinit {
        notificationsSubscription?.cancel()
    }

    /// Used to reload the Hub menu screen when selected site changes
    ///
    func activate(siteID: Int64) {
        hubMenuController = HubMenuViewController(siteID: siteID,
                                                  stores: storesManager,
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

    private func handleNotification(_ notification: WooCommerce.PushNotification) {
        guard notification.kind == .comment else {
            return
        }

        guard let noteID = notification.noteID else {
            return attemptRetrieveProductReviewWithoutNoteID(notification: notification)
        }
        let action = ProductReviewAction.retrieveProductReviewFromNote(noteID: Int64(noteID)) { [weak self] result in
            self?.handleProductReviewResult(result)
        }
        storesManager.dispatch(action)
    }

    private func attemptRetrieveProductReviewWithoutNoteID(notification: PushNotification) {
        guard let reviewID = notification.meta?.identifier(forKey: .comment) else {
            return
        }
        let action = ProductReviewAction.retrieveProductReviewAndProduct(
            siteID: notification.siteID,
            reviewID: Int64(reviewID),
            onCompletion: { [weak self] result in
                self?.handleProductReviewResult(result)
            })
        storesManager.dispatch(action)
    }

    private func handleProductReviewResult(_ result: Result<ProductReviewFromNoteParcel, Error>) {
        switch result {
        case .failure:
            noticePresenter.enqueue(notice: Notice(title: Localization.failedToRetrieveReviewNotificationDetails))
        case .success(let parcel):
            let siteID = parcel.review.siteID

            // Switch to the correct store first if needed
            self.switchStoreUseCase.switchStore(with: siteID) { [weak self] siteChanged in
                guard let self else {
                    return
                }

                Task { @MainActor in
                    ServiceLocator.analytics.track(.reviewOpen)
                    await self.willPresentReviewDetailsFromPushNotification()
                    self.pushReviewDetailsViewController(using: parcel)

                    if siteChanged {
                        let presenter = SwitchStoreNoticePresenter(siteID: Int64(siteID),
                                                                   noticePresenter: self.noticePresenter)
                        presenter.presentStoreSwitchedNoticeWhenSiteIsAvailable(configuration: .switchingStores)
                    }
                }
            }
        }
    }

    private func pushReviewDetailsViewController(using parcel: ProductReviewFromNoteParcel) {
        hubMenuController?.pushReviewDetailsViewController(using: parcel)
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
