import Combine
import SwiftUI

/// Wraps `CardPresentPaymentAlertViewModel` and provides additional optional view models for custom navigation initiated from the alert in SwiftUI.
final class CardPresentPaymentAlertSwiftUIViewModel: ObservableObject {
    let alertViewModel: CardPresentPaymentAlertViewModel

    /// Optional view model to present a WC settings web view if the alert view model conforms to
    /// `CardPresentPaymentsModalViewModelWCSettingsWebViewPresenting`.
    @Published var wcSettingsWebViewModel: WCSettingsWebViewModel?

    init(alertViewModel: CardPresentPaymentAlertViewModel) {
        self.alertViewModel = alertViewModel
        observeWebViewPresenting()
    }
}

private extension CardPresentPaymentAlertSwiftUIViewModel {
    func observeWebViewPresenting() {
        let webViewPublisher = (alertViewModel as? CardPresentPaymentsModalViewModelWCSettingsWebViewPresenting)?.webViewModel ??
        Just<WCSettingsWebViewModel?>(nil).eraseToAnyPublisher()
        webViewPublisher.assign(to: &$wcSettingsWebViewModel)
    }
}
