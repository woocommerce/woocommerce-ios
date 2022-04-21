import Foundation
import Yosemite
import Combine

/// View Model for the Edit Customer Note screen
///
final class EditCustomerNoteViewModel: EditCustomerNoteViewModelProtocol {

    /// Binding property modified at the view level.
    ///
    @Published var newNote: String

    /// Defaults to a disabled done button.
    ///
    @Published private(set) var navigationTrailingItem: EditCustomerNoteNavigationItem = .done(enabled: false)

    /// Presents either a success or an error notice in the tab bar context after the update operation is done.
    ///
    private let systemNoticePresenter: NoticePresenter

    /// Order to be edited.
    ///
    private let order: Order


    /// Action dispatcher
    ///
    private let stores: StoresManager

    /// Analytics center.
    ///
    private let analytics: Analytics

    init(order: Order,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics,
         systemNoticePresenter: NoticePresenter = ServiceLocator.noticePresenter) {
        self.order = order
        self.newNote = order.customerNote ?? ""
        self.stores = stores
        self.analytics = analytics
        self.systemNoticePresenter = systemNoticePresenter
        bindNavigationTrailingItemPublisher()
    }

    /// Update the note remotely and invoke a completion block when finished
    ///
    func updateNote(onFinish: @escaping (Bool) -> Void) {
        performUpdateOrderOptimistically(customerNote: newNote, onFinish: onFinish)
    }

    /// Track the flow cancel scenario.
    ///
    func userDidCancelFlow() {
        analytics.track(event: WooAnalyticsEvent.OrderDetailsEdit.orderDetailEditFlowCanceled(subject: .customerNote))
    }
}

// MARK: Helper Methods
private extension EditCustomerNoteViewModel {
    /// Calculates what navigation trailing item should be shown depending on our internal state.
    ///
    func bindNavigationTrailingItemPublisher() {
        $newNote
            .map { [weak self] editedContent -> EditCustomerNoteNavigationItem in
                .done(enabled: editedContent != self?.order.customerNote)
            }
            .assign(to: &$navigationTrailingItem)
    }

    /// Dispatches the action to update the order optimistically.
    /// - Parameters:
    ///   - customerNote: Given new customer note to update the order.
    ///   - onFinish: Callback to notify when the action has finished.
    ///
    func performUpdateOrderOptimistically(customerNote: String?, onFinish: ((Bool) -> Void)? = nil) {
        let updateAction = makeUpdateCustomerNoteAction(withNote: customerNote, onFinish: onFinish)
        stores.dispatch(updateAction)
    }

    /// Makes an `updateOrderOptimistically` action from a given customer note.
    /// - Parameters:
    ///   - note: Given new customer note to update the order.
    ///   - onFinish: Callback to notify when the action has finished.
    /// - Returns: A new `updateOrderOptimistically` action using the given parameters.
    ///
    func makeUpdateCustomerNoteAction(withNote note: String?, onFinish: ((Bool) -> Void)? = nil) -> Action {
        let orderID = order.orderID
        let modifiedOrder = order.copy(customerNote: note)
        return OrderAction.updateOrderOptimistically(siteID: order.siteID, order: modifiedOrder, fields: [.customerNote]) { [weak self] result in
            guard case let .failure(error) = result else {
                self?.analytics.track(event: WooAnalyticsEvent.OrderDetailsEdit.orderDetailEditFlowCompleted(subject: .customerNote))
                onFinish?(true)
                return
            }

            DDLogError("⛔️ Order Update Failure: [\(orderID).customerNote = \(note ?? "")]. Error: \(error)")

            self?.analytics.track(event: WooAnalyticsEvent.OrderDetailsEdit.orderDetailEditFlowFailed(subject: .customerNote))
            self?.displayUpdateErrorNotice(customerNote: note)
            onFinish?(false)
        }
    }

    /// Enqueues the `Order Updated` Notice. Whenever the `Undo` button gets pressed, we'll execute the `onUndoAction` closure.
    ///
    func displayCustomerNoteUpdatedNotice(onUndoAction: @escaping () -> Void) {
        let notice = Notice(title: Localization.success,
                            feedbackType: .success,
                            actionTitle: Localization.undo,
                            actionHandler: onUndoAction)
        systemNoticePresenter.enqueue(notice: notice)
    }

    /// Enqueues the `Unable to Change Customer Note of Order` Notice.
    ///
    func displayUpdateErrorNotice(customerNote: String?) {
        let notice = Notice(title: Localization.error,
                            feedbackType: .error,
                            actionTitle: Localization.retry) { [weak self] in
            self?.performUpdateOrderOptimistically(customerNote: customerNote)
        }

        systemNoticePresenter.enqueue(notice: notice)
    }
}

// MARK: Localization
private extension EditCustomerNoteViewModel {
    enum Localization {
        static let success = NSLocalizedString("Successfully updated", comment: "Notice text after updating the order successfully")
        static let error = NSLocalizedString("There was an error updating the order", comment: "Notice text after failing to update the order successfully")
        static let retry = NSLocalizedString("Retry", comment: "Retry Action")
        static let undo = NSLocalizedString("Undo", comment: "Undo Action")
    }
}
