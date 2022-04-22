import Foundation
import Yosemite
import Combine
import Experiments

/// View Model for the Edit Customer Note screen
///
final class EditCustomerNoteViewModel: EditCustomerNoteViewModelProtocol {

    /// Binding property modified at the view level.
    ///
    @Published var newNote: String

    /// Defaults to a disabled done button.
    ///
    @Published private(set) var navigationTrailingItem: EditCustomerNoteNavigationItem = .done(enabled: false)

    /// Indicates whether we must wait for the request before dismiss.
    ///
    var shouldWaitForRequestIsFinishedToDismiss: Bool {
        !areOptimisticUpdatesEnabled
    }

    /// Presents an error notice in the tab bar context after the update operation fails.
    ///
    private let noticePresenter: NoticePresenter

    /// Order to be edited.
    ///
    private var order: Order {
        didSet {
            syncNewNoteAfterUpdatingOrder()
        }
    }

    /// Tracks if a network request is being performed.
    ///
    private let performingNetworkRequest: CurrentValueSubject<Bool, Never> = .init(false)

    /// Action dispatcher
    ///
    private let stores: StoresManager

    /// Analytics center.
    ///
    private let analytics: Analytics

    /// Service to check if a feature flag is enabled.
    ///
    private let featureFlagService: FeatureFlagService

    init(order: Order,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics,
         noticePresenter: NoticePresenter = ServiceLocator.noticePresenter,
         featureFlagService: FeatureFlagService = ServiceLocator.featureFlagService) {
        self.order = order
        self.newNote = order.customerNote ?? ""
        self.stores = stores
        self.analytics = analytics
        self.noticePresenter = noticePresenter
        self.featureFlagService = featureFlagService
        bindNavigationTrailingItemPublisher()
    }

    func update(order: Order) {
        self.order = order
    }

    /// Update the note remotely and invoke a completion block when finished
    ///
    func updateNote(onFinish: @escaping (Bool) -> Void) {
        dispatchUpdateOrderOptimisticallyAction(withNote: newNote, onFinish: onFinish)
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
        Publishers.CombineLatest($newNote, performingNetworkRequest)
            .map { [weak self] newNote, performingNetworkRequest -> EditCustomerNoteNavigationItem in
                let optimisticUpdatesEnabled = self?.areOptimisticUpdatesEnabled ?? false
                guard optimisticUpdatesEnabled || !performingNetworkRequest else {
                    return .loading
                }
                return .done(enabled: self?.order.customerNote != newNote)
            }
            .assign(to: &$navigationTrailingItem)
    }

    /// Indicates whether the optimistic updates are enabled.
    ///
    var areOptimisticUpdatesEnabled: Bool {
        featureFlagService.isFeatureFlagEnabled(.updateOrderOptimistically)
    }

    /// Updates the temporal note after updating the order.
    ///
    func syncNewNoteAfterUpdatingOrder() {
        newNote = order.customerNote ?? ""
    }

    /// Dispatches the action to update the order optimistically.
    /// - Parameters:
    ///   - customerNote: Given new customer note to update the order.
    ///   - onFinish: Callback to notify when the action has finished.
    ///
    func dispatchUpdateOrderOptimisticallyAction(withNote customerNote: String?, onFinish: ((Bool) -> Void)? = nil) {
        let orderID = order.orderID
        let modifiedOrder = order.copy(customerNote: customerNote)

        let updateAction = makeUpdateAction(order: modifiedOrder) { [weak self] result in
            self?.performingNetworkRequest.send(false)

            guard case let .failure(error) = result else {
                self?.analytics.track(event: WooAnalyticsEvent.OrderDetailsEdit.orderDetailEditFlowCompleted(subject: .customerNote))
                onFinish?(true)
                return
            }

            DDLogError("⛔️ Order Update Failure: [\(orderID).customerNote = \(customerNote ?? "")]. Error: \(error)")

            self?.analytics.track(event: WooAnalyticsEvent.OrderDetailsEdit.orderDetailEditFlowFailed(subject: .customerNote))
            self?.displayUpdateErrorNotice(customerNote: customerNote)
            onFinish?(false)
        }

        performingNetworkRequest.send(true)
        stores.dispatch(updateAction)
    }

    /// Returns the update action based on the value of the `updateOrderOptimistically` feature flag.
    ///
    func makeUpdateAction(order: Order, onCompletion: @escaping (Result<Order, Error>) -> Void) -> Action {
        if areOptimisticUpdatesEnabled {
            return OrderAction.updateOrderOptimistically(siteID: order.siteID, order: order, fields: [.customerNote], onCompletion: onCompletion)
        } else {
            return OrderAction.updateOrder(siteID: order.siteID, order: order, fields: [.customerNote], onCompletion: onCompletion)
        }
    }

    /// Enqueues the `Unable to Change Customer Note of Order` Notice.
    ///
    func displayUpdateErrorNotice(customerNote: String?) {
        let notice = Notice(title: Localization.error,
                            feedbackType: .error,
                            actionTitle: Localization.retry) { [weak self] in
            self?.dispatchUpdateOrderOptimisticallyAction(withNote: customerNote)
        }

        noticePresenter.enqueue(notice: notice)
    }
}

// MARK: Localization
private extension EditCustomerNoteViewModel {
    enum Localization {
        static let success = NSLocalizedString("Successfully updated", comment: "Notice text after updating the order successfully")
        static let error = NSLocalizedString("There was an error updating the order", comment: "Notice text after failing to update the order successfully")
        static let retry = NSLocalizedString("Retry", comment: "Retry Action")
    }
}
