import SwiftUI

struct CardPresentPaymentAlert: View {
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

#Preview {
    let alertViewModel = CardPresentModalFoundReader(name: "Stripe M2", connect: {}, continueSearch: {}, cancel: {})
    return CardPresentPaymentAlert(alertViewModel: alertViewModel)
}
