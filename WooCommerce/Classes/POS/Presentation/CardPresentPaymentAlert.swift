import SwiftUI

struct CardPresentPaymentAlert: View {
    private let alertType: CardPresentPaymentAlertType

    init(alertType: CardPresentPaymentAlertType) {
        self.alertType = alertType
    }

    var body: some View {
        switch alertType {
        case .scanningForReaders(let alertViewModel):
            CardPresentPaymentScanningForReadersView(viewModel: alertViewModel)
        case .scanningFailed(let alertViewModel):
            CardPresentPaymentScanningForReadersFailedView(viewModel: alertViewModel)
        case .bluetoothRequired(let alertViewModel):
            CardPresentPaymentBluetoothRequiredAlertView(viewModel: alertViewModel)
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
        case .connectingFailedNonRetryable(let alertViewModel):
            CardPresentPaymentConnectingFailedNonRetryableView(viewModel: alertViewModel)
        case .connectingFailedChargeReader(let alertViewModel):
            CardPresentPaymentConnectingFailedChargeReaderView(viewModel: alertViewModel)
        case .connectingFailedUpdateAddress(let alertViewModel):
            CardPresentPaymentConnectingFailedUpdateAddressView(viewModel: alertViewModel)
        case .connectingFailedUpdatePostalCode(let alertViewModel):
            CardPresentPaymentConnectingFailedUpdatePostalCodeView(viewModel: alertViewModel)
        }
    }
}
