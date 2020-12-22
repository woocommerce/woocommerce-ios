import Foundation
import Yosemite

/// Constructs and enqueues a `Notice` for informing the user that the selected site was changed.
///
final class SwitchStoreNoticePresenter {

    private let sessionManager: SessionManagerProtocol
    private let noticePresenter: NoticePresenter

    init(sessionManager: SessionManagerProtocol = ServiceLocator.stores.sessionManager,
         noticePresenter: NoticePresenter = ServiceLocator.noticePresenter) {
        self.sessionManager = sessionManager
        self.noticePresenter = noticePresenter
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

        let messageFormat = NSLocalizedString("Switched to %1$@. You will only receive notifications from this store.",
                                              comment: "Message presented after users switch to a new store. "
                                                + "Reads like: Switched to {store name}. You will only receive notifications from this store. "
                                                + "Parameters: %1$@ - store name")
        let message = String.localizedStringWithFormat(messageFormat, newStoreName)
        let notice = Notice(title: message, feedbackType: .success)

        noticePresenter.enqueue(notice: notice)
    }
}
