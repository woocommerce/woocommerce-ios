import SwiftUI

struct CardPresentPaymentConnectingFailedUpdateAddressView: View {
    let viewModel: CardPresentPaymentConnectingFailedUpdateAddressAlertViewModel
    var body: some View {
        Text("Connecting failed - update address")
    }
}

#Preview {
    CardPresentPaymentConnectingFailedUpdateAddressView(
        viewModel: CardPresentPaymentConnectingFailedUpdateAddressAlertViewModel())
}
