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

    var onDismiss: (() -> Void)? {
        switch self {
        case .scanningForReaders(let viewModel):
            return viewModel.buttonViewModel.actionHandler
        case .scanningFailed(let viewModel):
            return viewModel.buttonViewModel.actionHandler
        case .bluetoothRequired(let viewModel):
            return viewModel.dismissButtonViewModel.actionHandler
        case .foundReader(let viewModel):
            return viewModel.cancelSearchButton.actionHandler
        case .foundMultipleReaders(let viewModel):
            return viewModel.cancelSearch
        case .requiredReaderUpdateInProgress(let viewModel):
            return viewModel.cancelReaderUpdate
        case .optionalReaderUpdateInProgress(let viewModel):
            return viewModel.cancelReaderUpdate
        case .readerUpdateCompletion:
            // We only support in-line updates at the moment, and they automatically move on to connecting the reader.
            return nil
        case .updateFailed(let viewModel):
            return viewModel.cancelButtonViewModel.actionHandler
        case .updateFailedNonRetryable(let viewModel):
            return viewModel.cancelButtonViewModel.actionHandler
        case .updateFailedLowBattery(let viewModel):
            return viewModel.cancelButtonViewModel.actionHandler
        case .connectingToReader:
            return nil
        case .connectingFailed(let viewModel):
            return viewModel.cancelButtonViewModel.actionHandler
        case .connectingFailedNonRetryable(let viewModel):
            return viewModel.cancelButtonViewModel.actionHandler
        case .connectingFailedChargeReader(let viewModel):
            return viewModel.cancelButtonViewModel.actionHandler
        case .connectingFailedUpdateAddress(let viewModel):
            return viewModel.cancelButtonViewModel.actionHandler
        case .connectingFailedUpdatePostalCode(let viewModel):
            return viewModel.cancelButtonViewModel.actionHandler
        case .connectionSuccess(let viewModel):
            return viewModel.buttonViewModel.actionHandler
        }
    }

    var isDismissDisabled: Bool {
        onDismiss == nil
    }
}
