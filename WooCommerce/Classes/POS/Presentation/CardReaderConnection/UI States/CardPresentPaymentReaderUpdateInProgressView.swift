import SwiftUI

struct CardPresentPaymentReaderUpdateInProgressView: View {
    private let viewModel: CardPresentPaymentUpdatingReaderAlertViewModel

    init(viewModel: CardPresentPaymentUpdatingReaderAlertViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Text("Updating reader...")
    }
}

#Preview {
    CardPresentPaymentReaderUpdateInProgressView(viewModel: CardPresentPaymentUpdatingReaderAlertViewModel())
}
