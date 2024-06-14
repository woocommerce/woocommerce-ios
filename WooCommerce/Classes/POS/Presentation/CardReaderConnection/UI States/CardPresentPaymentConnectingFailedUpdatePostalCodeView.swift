import SwiftUI

struct CardPresentPaymentConnectingFailedUpdatePostalCodeView: View {
    let viewModel: CardPresentPaymentConnectingFailedUpdatePostalCodeAlertViewModel

    var body: some View {
        Text("Connecting failed – update postal code")
    }
}

#Preview {
    CardPresentPaymentConnectingFailedUpdatePostalCodeView(
        viewModel: CardPresentPaymentConnectingFailedUpdatePostalCodeAlertViewModel())
}
