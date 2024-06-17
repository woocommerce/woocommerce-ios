import SwiftUI

struct PointOfSaleCardPresentPaymentAlert: View {
    private let alertType: PointOfSaleCardPresentPaymentAlertType

    init(alertType: PointOfSaleCardPresentPaymentAlertType) {
        self.alertType = alertType
    }

    var body: some View {
        switch alertType {
        case .scanningForReaders(let alertViewModel):
            PointOfSaleCardPresentPaymentScanningForReadersView(viewModel: alertViewModel)
        case .scanningFailed(let alertViewModel):
            PointOfSaleCardPresentPaymentScanningForReadersFailedView(viewModel: alertViewModel)
        case .bluetoothRequired(let alertViewModel):
            PointOfSaleCardPresentPaymentBluetoothRequiredAlertView(viewModel: alertViewModel)
        case .foundReader(let alertViewModel):
            PointOfSaleCardPresentPaymentFoundReadersView(viewModel: alertViewModel)
        case .updatingReader(let alertViewModel):
            CardPresentPaymentReaderUpdateInProgressView(viewModel: alertViewModel)
        case .updateFailed(let alertViewModel):
            CardPresentPaymentReaderUpdateFailedView(viewModel: alertViewModel)
        case .connectingToReader(let alertViewModel):
            PointOfSaleCardPresentPaymentConnectingToReaderView(viewModel: alertViewModel)
        case .connectingFailed(let alertViewModel):
            PointOfSaleCardPresentPaymentConnectingFailedView(viewModel: alertViewModel)
        case .connectingFailedNonRetryable(let alertViewModel):
            PointOfSaleCardPresentPaymentConnectingFailedNonRetryableView(viewModel: alertViewModel)
        case .connectingFailedChargeReader(let alertViewModel):
            PointOfSaleCardPresentPaymentConnectingFailedChargeReaderView(viewModel: alertViewModel)
        case .connectingFailedUpdateAddress(let alertViewModel):
            PointOfSaleCardPresentPaymentConnectingFailedUpdateAddressView(viewModel: alertViewModel)
        case .connectingFailedUpdatePostalCode(let alertViewModel):
            PointOfSaleCardPresentPaymentConnectingFailedUpdatePostalCodeView(viewModel: alertViewModel)
        }
    }
}
