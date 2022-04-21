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

    /// Defaults to `nil`.
    ///
    @Published var presentNotice: EditCustomerNoteNotice?

    /// Publisher accessor for `presentNotice`. Needed for the protocol conformance.
    ///
    var presentNoticePublisher: Published<EditCustomerNoteNotice?>.Publisher {
        $presentNotice
    }

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
        let modifiedOrder = order.copy(customerNote: newNote)
        let action = OrderAction.updateOrder(siteID: order.siteID, order: modifiedOrder, fields: [.customerNote]) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success:
                self.systemNoticePresenter.enqueue(notice: .init(title: Localization.success, feedbackType: .success))
                self.analytics.track(event: WooAnalyticsEvent.OrderDetailsEdit.orderDetailEditFlowCompleted(subject: .customerNote))
            case .failure(let error):
                self.systemNoticePresenter.enqueue(notice: .init(title: Localization.error, feedbackType: .error))
                self.analytics.track(event: WooAnalyticsEvent.OrderDetailsEdit.orderDetailEditFlowFailed(subject: .customerNote))
                DDLogError("⛔️ Unable to update the order: \(error)")
            }

            onFinish(result.isSuccess)
        }

        stores.dispatch(action)
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
}

// MARK: Localization
private extension EditCustomerNoteViewModel {
    enum Localization {
        static let success = NSLocalizedString("Successfully updated", comment: "Notice text after updating the order successfully")
        static let error = NSLocalizedString("There was an error updating the order", comment: "Notice text after failing to update the order successfully")
    }
}
