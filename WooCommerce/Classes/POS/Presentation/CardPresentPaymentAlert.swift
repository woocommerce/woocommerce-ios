import SwiftUI

typealias CardPresentPaymentsWebViewPresentingAlertViewModel = CardPresentPaymentsModalViewModelContent & CardPresentPaymentsModalViewModelActions & CardPresentPaymentsModalViewModelWebViewPresenting & ObservableObject

struct CardPresentPaymentAlert: View {
    let alertViewModel: CardPresentPaymentAlertViewModel

    var body: some View {
        if let webViewPresentingViewModel = alertViewModel as? CardPresentPaymentsWebViewPresentingAlertViewModel {
            WebViewPresentingCardPresentPaymentAlert(alertViewModel: webViewPresentingViewModel)
        } else {
            BasicCardPresentPaymentAlert(alertViewModel: alertViewModel)
        }
    }
}

struct BasicCardPresentPaymentAlert: View {
    let alertViewModel: CardPresentPaymentAlertViewModel

    var body: some View {
        VStack {
            Text(alertViewModel.topTitle)

            if let bottomTitle = alertViewModel.bottomTitle {
                Text(bottomTitle)
            }

            if let primaryButton = alertViewModel.primaryButtonViewModel {
                Button(primaryButton.title, action: primaryButton.actionHandler)
            }

            if let secondaryButton = alertViewModel.secondaryButtonViewModel {
                Button(secondaryButton.title, action: secondaryButton.actionHandler)
            }

            if let auxiliaryButton = alertViewModel.auxiliaryButtonViewModel {
                Button(auxiliaryButton.title, action: auxiliaryButton.actionHandler)
            }
        }
    }
}

struct WebViewPresentingCardPresentPaymentAlert: View {
    @ObservedObject var alertViewModel: any CardPresentPaymentsWebViewPresentingAlertViewModel

    var body: some View {
        BasicCardPresentPaymentAlert(alertViewModel: alertViewModel)
            .sheet(item: $alertViewModel.webViewModel) { webViewModel in
                WCSettingsWebView(adminUrl: webViewModel.webViewURL, completion: webViewModel.onCompletion)
            }
    }
}

#Preview {
    let alertViewModel = CardPresentModalFoundReader(name: "Stripe M2", connect: {}, continueSearch: {}, cancel: {})
    return CardPresentPaymentAlert(alertViewModel: alertViewModel)
}
