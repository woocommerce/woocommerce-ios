import SwiftUI

struct CardPresentPaymentAlert: View {
    private let viewModel: CardPresentPaymentAlertViewModel

    init(viewModel: CardPresentPaymentAlertViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        switch viewModel {
        case .scanningForReaders(let alertViewModel):
            CardPresentPaymentScanningForReadersView(viewModel: alertViewModel)
        case .scanningFailed(let alertViewModel):
            CardPresentPaymentScanningForReadersFailedView(viewModel: alertViewModel)
        case .foundReader(let alertViewModel):
            CardPresentPaymentFoundReadersView(viewModel: alertViewModel)
        case .updatingReader(let alertViewModel):
            CardPresentPaymentReaderUpdateInProgressView(viewModel: alertViewModel)
        case .updateFailed(let alertViewModel):
            CardPresentPaymentReaderUpdateFailedView(viewModel: alertViewModel)
        case .connectingToReader(let alertViewModel):
            CardPresentPaymentConnectingToReaderView(viewModel: alertViewModel)
        case .connectingFailed(let alertViewModel):
            CardPresentPaymentConnectingFailedView(viewModel: alertViewModel)
        /// Note that the payment alerts below will mostly/all be displayed inline, so may need different treatment,
        /// possibly not being supported within this enum/view at all.
        /// Error is the main exception to this.
        case .preparingForPayment(let alertViewModel):
            Text("Preparing for payment")
        case .tapSwipeOrInsertCard(let alertViewModel):
            Text("Tap card")
        case .processing(let alertViewModel):
            Text("Processing")
        case .displayReaderMessage(let alertViewModel):
            Text("Display reader message")
        case .success(let alertViewModel):
            Text("Success")
        case .error(let alertViewModel):
            Text("Error")
        }
    }
}
