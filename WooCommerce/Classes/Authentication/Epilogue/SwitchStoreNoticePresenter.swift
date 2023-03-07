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
    private var cancellables = Set<AnyCancellable>()

    init(siteID: Int64,
         stores: StoresManager = ServiceLocator.stores,
         noticePresenter: NoticePresenter = ServiceLocator.noticePresenter) {
        self.siteID = siteID
        self.stores = stores
        self.noticePresenter = noticePresenter
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
            // Since we only want to show the notice once the site becomes available, we only need the first value here.
            .first()
            .sink { [weak self] site in
            self?.presentStoreSwitchedNotice(site: site)
        }.store(in: &cancellables)
    }

    /// Present the switch notice to the user, with the new configured store name.
    ///
    func presentStoreSwitchedNotice(site: Site) {
        let newStoreName = site.name

        let titleFormat = Localization.titleFormat
        let title = String.localizedStringWithFormat(titleFormat, newStoreName)
        let notice = Notice(title: title, feedbackType: .success)

        noticePresenter.enqueue(notice: notice)
    }
}

extension SwitchStoreNoticePresenter {
    enum Localization {
        static let titleFormat = NSLocalizedString("Switched to %1$@.",
                                                   comment: "Message presented after users switch to a new store. "
                                                    + "Reads like: Switched to {store name}. "
                                                    + "Parameters: %1$@ - store name")
    }
}
