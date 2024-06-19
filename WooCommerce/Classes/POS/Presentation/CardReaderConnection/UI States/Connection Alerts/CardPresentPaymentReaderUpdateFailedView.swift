import SwiftUI

struct CardPresentPaymentReaderUpdateFailedView: View {
    private let viewModel: CardPresentPaymentReaderUpdateFailedAlertViewModel

    init(viewModel: CardPresentPaymentReaderUpdateFailedAlertViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Text("Reader update failed")
    }
}

#Preview {
    CardPresentPaymentReaderUpdateFailedView(viewModel: CardPresentPaymentReaderUpdateFailedAlertViewModel())
}
