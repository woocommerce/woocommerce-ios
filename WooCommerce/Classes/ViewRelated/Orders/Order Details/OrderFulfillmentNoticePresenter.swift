import Foundation
import Combine

final class OrderFulfillmentNoticePresenter {

    private let noticePresenter: NoticePresenter = ServiceLocator.noticePresenter
    private let analytics: Analytics = ServiceLocator.analytics

    private var cancellables = Set<AnyCancellable>()

    func present(process: OrderFulfillmentUseCase.FulfillmentProcess) {
        displayOptimisticFulfillmentNotice(process)
        observe(fulfillmentProcess: process)
    }

    private func observe(fulfillmentProcess: OrderFulfillmentUseCase.FulfillmentProcess) {
        var cancellable: AnyCancellable = AnyCancellable { }
        cancellable = fulfillmentProcess.result.sink { completion in
            if case .failure(let fulfillmentError) = completion {
                self.displayFulfillmentErrorNotice(error: fulfillmentError)
            }

            cancellable.cancel()
        } receiveValue: {
            // noop
        }

        cancellables.insert(cancellable)
    }

    /// Displays the `Order Fulfilled` Notice.
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
