import SwiftUI

struct CardPresentPaymentConnectingFailedChargeReaderView: View {
    let viewModel: CardPresentPaymentConnectingFailedChargeReaderAlertViewModel
    var body: some View {
        Text("Connecting failed – charge reader")
    }
}

#Preview {
    CardPresentPaymentConnectingFailedChargeReaderView(
        viewModel: CardPresentPaymentConnectingFailedChargeReaderAlertViewModel())
}
