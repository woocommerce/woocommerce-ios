import SwiftUI

struct CardPresentPaymentScanningForReadersFailedView: View {
    private let viewModel: CardPresentPaymentScanningFailedAlertViewModel

    init(viewModel: CardPresentPaymentScanningFailedAlertViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Text("Reader scanning failed")
    }
}

#Preview {
    CardPresentPaymentScanningForReadersFailedView(viewModel: CardPresentPaymentScanningFailedAlertViewModel())
}
