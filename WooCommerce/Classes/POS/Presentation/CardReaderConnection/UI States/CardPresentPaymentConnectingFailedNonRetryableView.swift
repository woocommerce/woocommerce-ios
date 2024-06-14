import SwiftUI

struct CardPresentPaymentConnectingFailedNonRetryableView: View {
    let viewModel: CardPresentPaymentConnectingFailedNonRetryableAlertViewModel
    var body: some View {
        Text("Connecting failed – non retryable")
    }
}

#Preview {
    CardPresentPaymentConnectingFailedNonRetryableView(
        viewModel: CardPresentPaymentConnectingFailedNonRetryableAlertViewModel())
}
