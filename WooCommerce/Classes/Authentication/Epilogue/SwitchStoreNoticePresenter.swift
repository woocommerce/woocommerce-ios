import Experiments
import Foundation
import Yosemite

/// Constructs and enqueues a `Notice` for informing the user that the selected site was changed.
///
final class SwitchStoreNoticePresenter {

    private let sessionManager: SessionManagerProtocol
    private let noticePresenter: NoticePresenter
    private let featureFlagService: FeatureFlagService

    init(sessionManager: SessionManagerProtocol = ServiceLocator.stores.sessionManager,
         noticePresenter: NoticePresenter = ServiceLocator.noticePresenter,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService) {
        self.sessionManager = sessionManager
        self.noticePresenter = noticePresenter
        self.featureFlagService = featureFlagService
    }

    /// Present the switch notice to the user, with the new configured store name.
    ///
    func presentStoreSwitchedNotice(configuration: StorePickerConfiguration?) {
        guard configuration == .switchingStores else {
            return
        }
        guard let newStoreName = sessionManager.defaultSite?.name else {
            return
        }

        let titleFormat = featureFlagService.isFeatureFlagEnabled(.pushNotificationsForAllStores) ?
            Localization.titleFormat: Localization.titleFormatWithPushNotificationsForAllStoresDisabled
        let title = String.localizedStringWithFormat(titleFormat, newStoreName)
        let notice = Notice(title: title, feedbackType: .success)

        noticePresenter.enqueue(notice: notice)
    }
}

extension SwitchStoreNoticePresenter {
    enum Localization {
        static let titleFormatWithPushNotificationsForAllStoresDisabled =
            NSLocalizedString("Switched to %1$@. You will only receive notifications from this store.",
                              comment: "Message presented after users switch to a new store when multi-store push notifications are not supported. "
                                + "Reads like: Switched to {store name}. You will only receive notifications from this store. "
                                + "Parameters: %1$@ - store name")
        static let titleFormat = NSLocalizedString("Switched to %1$@.",
                                                   comment: "Message presented after users switch to a new store. "
                                                    + "Reads like: Switched to {store name}. "
                                                    + "Parameters: %1$@ - store name")
    }
}
