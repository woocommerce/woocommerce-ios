import SwiftUI

struct CardPresentPaymentConnectingToReaderView: View {
    private let viewModel: CardPresentPaymentConnectingToReaderAlertViewModel

    init(viewModel: CardPresentPaymentConnectingToReaderAlertViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Text("Connecting to reader...")
    }
}

#Preview {
    CardPresentPaymentConnectingToReaderView(viewModel: CardPresentPaymentConnectingToReaderAlertViewModel())
}
