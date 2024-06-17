import SwiftUI

struct CardPresentPaymentConnectingFailedView: View {
    private let viewModel: CardPresentPaymentConnectingFailedAlertViewModel

    init(viewModel: CardPresentPaymentConnectingFailedAlertViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Text("Connection to reader failed")
    }
}

#Preview {
    CardPresentPaymentConnectingFailedView(viewModel: CardPresentPaymentConnectingFailedAlertViewModel())
}
