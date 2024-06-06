import Combine
import SwiftUI

/// Wraps `CardPresentPaymentAlertViewModel` and provides additional optional view models for custom navigation initiated from the alert in SwiftUI.
final class CardPresentPaymentAlertSwiftUIViewModel: ObservableObject {
    let alertViewModel: CardPresentPaymentAlertViewModel

    /// Optional view model to present a web view if the alert view model conforms to `CardPresentPaymentsModalViewModelWebViewPresenting`.
    @Published var webViewModel: CardPresentPaymentsWebViewModel?

    init(alertViewModel: CardPresentPaymentAlertViewModel) {
        self.alertViewModel = alertViewModel
        observeWebViewPresenting()
    }
}

private extension CardPresentPaymentAlertSwiftUIViewModel {
    func observeWebViewPresenting() {
        let webViewPublisher = (alertViewModel as? CardPresentPaymentsModalViewModelWebViewPresenting)?.webViewModel ??
        Just<CardPresentPaymentsWebViewModel?>(nil).eraseToAnyPublisher()
        webViewPublisher.assign(to: &$webViewModel)
    }
}
