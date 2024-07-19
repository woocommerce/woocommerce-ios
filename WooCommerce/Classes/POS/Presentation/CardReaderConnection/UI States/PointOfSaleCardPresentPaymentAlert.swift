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
        case .foundMultipleReaders(let alertViewModel):
            PointOfSaleCardPresentPaymentFoundMultipleReadersView(viewModel: alertViewModel)
        case .requiredReaderUpdateInProgress(let alertViewModel):
            PointOfSaleCardPresentPaymentRequiredReaderUpdateInProgressView(viewModel: alertViewModel)
        case .optionalReaderUpdateInProgress(let alertViewModel):
            PointOfSaleCardPresentPaymentOptionalReaderUpdateInProgressView(viewModel: alertViewModel)
        case .readerUpdateCompletion(let alertViewModel):
            PointOfSaleCardPresentPaymentReaderUpdateCompletionView(viewModel: alertViewModel)
        case .updateFailed(let alertViewModel):
            PointOfSaleCardPresentPaymentReaderUpdateFailedView(viewModel: alertViewModel)
        case .updateFailedNonRetryable(let alertViewModel):
            PointOfSaleCardPresentPaymentReaderUpdateFailedNonRetryableView(viewModel: alertViewModel)
        case .updateFailedLowBattery(let alertViewModel):
            PointOfSaleCardPresentPaymentReaderUpdateFailedLowBatteryView(viewModel: alertViewModel)
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
