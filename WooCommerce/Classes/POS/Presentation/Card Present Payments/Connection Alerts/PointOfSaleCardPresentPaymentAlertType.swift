import Foundation

/// `PointOfSaleCardPresentPaymentAlertType` serves as a typed bridge between the `CardPresentPaymentEventDetails`
/// and the POS alert view models, for those events which should be displayed as alerts.
enum PointOfSaleCardPresentPaymentAlertType: Hashable, Identifiable {
    var id: Self {
        self
    }

    case scanningForReaders(viewModel: PointOfSaleCardPresentPaymentScanningForReadersAlertViewModel)
    case scanningFailed(viewModel: PointOfSaleCardPresentPaymentScanningFailedAlertViewModel)
    case bluetoothRequired(viewModel: PointOfSaleCardPresentPaymentBluetoothRequiredAlertViewModel)
    case foundReader(viewModel: PointOfSaleCardPresentPaymentFoundReaderAlertViewModel)
    case foundMultipleReaders(viewModel: PointOfSaleCardPresentPaymentFoundMultipleReadersAlertViewModel)
    case requiredReaderUpdateInProgress(viewModel: PointOfSaleCardPresentPaymentRequiredReaderUpdateInProgressAlertViewModel)
    case optionalReaderUpdateInProgress(viewModel: PointOfSaleCardPresentPaymentOptionalReaderUpdateInProgressAlertViewModel)
    case readerUpdateCompletion(viewModel: PointOfSaleCardPresentPaymentReaderUpdateCompletionAlertViewModel)
    case updateFailed(viewModel: PointOfSaleCardPresentPaymentReaderUpdateFailedAlertViewModel)
    case updateFailedNonRetryable(viewModel: PointOfSaleCardPresentPaymentReaderUpdateFailedNonRetryableAlertViewModel)
    case updateFailedLowBattery(viewModel: PointOfSaleCardPresentPaymentReaderUpdateFailedLowBatteryAlertViewModel)
    case connectingToReader(viewModel: PointOfSaleCardPresentPaymentConnectingToReaderAlertViewModel)
    case connectingFailed(viewModel: PointOfSaleCardPresentPaymentConnectingFailedAlertViewModel)
    case connectingFailedNonRetryable(viewModel: PointOfSaleCardPresentPaymentConnectingFailedNonRetryableAlertViewModel)
    case connectingFailedChargeReader(viewModel: PointOfSaleCardPresentPaymentConnectingFailedChargeReaderAlertViewModel)
    case connectingFailedUpdateAddress(viewModel: PointOfSaleCardPresentPaymentConnectingFailedUpdateAddressAlertViewModel)
    case connectingFailedUpdatePostalCode(viewModel: PointOfSaleCardPresentPaymentConnectingFailedUpdatePostalCodeAlertViewModel)
    case connectionSuccess(viewModel: PointOfSaleCardPresentPaymentConnectionSuccessAlertViewModel)
}
