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

    /// Order to be edited.
    ///
    private let order: Order

    /// Tracks if a network request is being performed.
    ///
    private let performingNetworkRequest: CurrentValueSubject<Bool, Never> = .init(false)

    /// Action dispatcher
    ///
    private let stores: StoresManager

    /// Analytics center.
    ///
    private let analytics: Analytics

    init(order: Order, stores: StoresManager = ServiceLocator.stores, analytics: Analytics = ServiceLocator.analytics) {
        self.order = order
        self.newNote = order.customerNote ?? ""
        self.stores = stores
        self.analytics = analytics
        bindNavigationTrailingItemPublisher()
    }

    /// Update the note remotely and invoke a completion block when finished
    ///
    func updateNote(onFinish: @escaping (Bool) -> Void) {
        let modifiedOrder = order.copy(customerNote: newNote)
        let action = OrderAction.updateOrder(siteID: order.siteID, order: modifiedOrder, fields: [.customerNote]) { [weak self] result in
            guard let self = self else { return }

            self.performingNetworkRequest.send(false)
            switch result {
            case .success:
                self.presentNotice = .success
                self.analytics.track(event: WooAnalyticsEvent.OrderDetailsEdit.orderDetailEditFlowCompleted(subject: .customerNote))
            case .failure(let error):
                self.presentNotice = .error
                self.analytics.track(event: WooAnalyticsEvent.OrderDetailsEdit.orderDetailEditFlowFailed(subject: .customerNote))
                DDLogError("⛔️ Unable to update the order: \(error)")
            }

            onFinish(result.isSuccess)
        }

        performingNetworkRequest.send(true)
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
    private func bindNavigationTrailingItemPublisher() {
        Publishers.CombineLatest($newNote, performingNetworkRequest)
            .map { [order] newNote, performingNetworkRequest -> EditCustomerNoteNavigationItem in
                guard !performingNetworkRequest else {
                    return .loading
                }
                return .done(enabled: order.customerNote != newNote)
            }
            .assign(to: &$navigationTrailingItem)
    }
}
