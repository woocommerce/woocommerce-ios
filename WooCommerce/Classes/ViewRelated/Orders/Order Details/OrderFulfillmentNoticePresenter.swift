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

    /// Represents notices titles.
    ///
    struct NoticeConfiguration {
        /// Custom success notice title.
        ///
        let successTitle: String

        /// Custom error notice title. When `nil` the concrete `error.message` will be used.
        ///
        let errorTitle: String?

        /// Default messages configuration.
        ///
        fileprivate static let `default` = NoticeConfiguration(
            successTitle: NSLocalizedString("🎉 Order Completed", comment: "Success notice when tapping Mark Order Complete on Review Order screen"),
            errorTitle: nil
        )
    }

    private let noticePresenter: NoticePresenter = ServiceLocator.noticePresenter
    private let analytics: Analytics = ServiceLocator.analytics
    private var noticeConfiguration: NoticeConfiguration
    private var cancellables = Set<AnyCancellable>()

    /// Custom initializer.
    /// Useful to provide a different message configuration
    ///
    init(noticeConfiguration: NoticeConfiguration = .default) {
        self.noticeConfiguration = noticeConfiguration
    }

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
        let message = noticeConfiguration.successTitle
        let actionTitle = NSLocalizedString("Undo", comment: "Undo Action")
        let notice = Notice(title: message, feedbackType: .success, actionTitle: actionTitle) {
            self.analytics.track(.orderMarkedCompleteUndoButtonTapped)

            self.observe(fulfillmentProcess: fulfillmentProcess.undo())
        }

        noticePresenter.enqueue(notice: notice)
    }

    private func displayFulfillmentErrorNotice(error: OrderFulfillmentUseCase.FulfillmentError) {
        let actionTitle = NSLocalizedString("Retry", comment: "Retry Action")
        let errorMessage = noticeConfiguration.errorTitle ?? error.message
        let notice = Notice(title: errorMessage, message: nil, feedbackType: .error, actionTitle: actionTitle) {
            self.observe(fulfillmentProcess: error.retry())
        }

        // Give the previous error notice(if any) time to be dismissed from the view.
        // If the previous error notice has not completely being dismissed(due to the animation time)
        // The new notice won't be shown because `noticePresenter` thinks it is already displaying a notice with the same title.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.noticePresenter.enqueue(notice: notice)
        }
    }
}
