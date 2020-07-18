import Foundation

/// Constructs and enqueues a `Notice` for informing the user that the site was switched.
///
final class SwitchStoreNoticePresenter {

    /// Present the switch notice to the user, with the new configured store name.
    ///
    static func presentStoreSwitchedNotice(stores: StoresManager, configuration: StorePickerConfiguration?) {
        guard configuration == .switchingStores else {
            return
        }
        guard let newStoreName = stores.sessionManager.defaultSite?.name else {
            return
        }

        let message = NSLocalizedString("Switched to \(newStoreName). You will only receive notifications from this store.",
            comment: "Message presented after users switch to a new store. "
                + "Reads like: Switched to {store name}. You will only receive notifications from this store.")
        let notice = Notice(title: message, feedbackType: .success)

        ServiceLocator.noticePresenter.enqueue(notice: notice)
    }
}
