import Foundation
import Combine

/// Presents notices for order fulfillment and handling of undos and retries.
///
/// This is the UI counterpart for `OrderFulfillmentUseCase`.
///
/// This class is meant to live longer than the `ViewController` that creates it. So a lot of the
/// calls in here will capture `self`. The reason is we want to notify users if something fails in
/// `OrderFulfillmentUseCase`. And we want to do this even if the user has already left the
/// `ViewController` (i.e. `OrderDetailsViewController`).
///
final class OrderFulfillmentNoticePresenter {

    private let noticePresenter: NoticePresenter = ServiceLocator.noticePresenter
    private let analytics: Analytics = ServiceLocator.analytics

    private var cancellables = Set<AnyCancellable>()

    /// Start presenting notices for the given fulfillment process.
    ///
    /// Undo and retry options will be presented to the user too.
    func present(process: OrderFulfillmentUseCase.FulfillmentProcess) {
        displayOptimisticFulfillmentNotice(process)
        observe(fulfillmentProcess: process)
    }

    /// Observe the given process and display error notices if needed.
    private func observe(fulfillmentProcess: OrderFulfillmentUseCase.FulfillmentProcess) {
        var cancellable: AnyCancellable = AnyCancellable { }
        cancellable = fulfillmentProcess.result.sink { completion in
            if case .failure(let fulfillmentError) = completion {
                self.displayFulfillmentErrorNotice(error: fulfillmentError)
            }

            self.cancellables.remove(cancellable)
        } receiveValue: {
            // Noop. There is no value to receive or act on.
        }

        // Insert in `cancellables` to keep the `sink` handler active.
        cancellables.insert(cancellable)
    }

    /// Notify the user that the order has been fulfillment.
    ///
    /// This is optimistic because the network call will still be ongoing by the time this is
    /// executed.
    ///
    private func displayOptimisticFulfillmentNotice(_ fulfillmentProcess: OrderFulfillmentUseCase.FulfillmentProcess) {
        let message = NSLocalizedString("Order marked as fulfilled", comment: "Order fulfillment success notice")
        let actionTitle = NSLocalizedString("Undo", comment: "Undo Action")
        let notice = Notice(title: message, feedbackType: .success, actionTitle: actionTitle) {
            self.analytics.track(.orderMarkedCompleteUndoButtonTapped)

            self.observe(fulfillmentProcess: fulfillmentProcess.undo())
        }

        noticePresenter.enqueue(notice: notice)
    }

    private func displayFulfillmentErrorNotice(error: OrderFulfillmentUseCase.FulfillmentError) {
        let actionTitle = NSLocalizedString("Retry", comment: "Retry Action")
        let notice = Notice(title: error.message, message: nil, feedbackType: .error, actionTitle: actionTitle) {
            self.observe(fulfillmentProcess: error.retry())
        }

        noticePresenter.enqueue(notice: notice)
    }
}
