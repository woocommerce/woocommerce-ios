import Combine
import Experiments
import Foundation
import Yosemite

/// Constructs and enqueues a `Notice` for informing the user that the selected site was changed.
///
final class SwitchStoreNoticePresenter {

    private let siteID: Int64
    private let stores: StoresManager
    private let noticePresenter: NoticePresenter
    private let featureFlagService: FeatureFlagService
    private var cancellables = Set<AnyCancellable>()

    init(siteID: Int64,
         stores: StoresManager = ServiceLocator.stores,
         noticePresenter: NoticePresenter = ServiceLocator.noticePresenter,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService) {
        self.siteID = siteID
        self.stores = stores
        self.noticePresenter = noticePresenter
        self.featureFlagService = featureFlagService
    }

    /// Present the switch notice to the user, with the new configured store name.
    ///
    func presentStoreSwitchedNoticeWhenSiteIsAvailable(configuration: StorePickerConfiguration) {
        guard configuration == .switchingStores else {
            return
        }
        observeSiteAndPresentWhenSiteNameIsAvailable()
    }
}

private extension SwitchStoreNoticePresenter {
    func observeSiteAndPresentWhenSiteNameIsAvailable() {
        stores.site.compactMap { $0 }
            .filter { $0.siteID == self.siteID }
            .first()
            .sink { [weak self] site in
            self?.presentStoreSwitchedNotice(site: site)
        }.store(in: &cancellables)
    }

    /// Present the switch notice to the user, with the new configured store name.
    ///
    func presentStoreSwitchedNotice(site: Site) {
        let newStoreName = site.name

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
