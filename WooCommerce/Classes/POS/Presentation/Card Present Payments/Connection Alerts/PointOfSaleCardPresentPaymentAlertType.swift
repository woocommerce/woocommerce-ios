import Foundation

/// `PointOfSaleCardPresentPaymentAlertType` serves as a typed bridge between the `CardPresentPaymentEventDetails`
/// and the POS alert view models, for those events which should be displayed as alerts.
enum PointOfSaleCardPresentPaymentAlertType {
    case scanningForReaders(viewModel: PointOfSaleCardPresentPaymentScanningForReadersAlertViewModel)
    case scanningFailed(viewModel: PointOfSaleCardPresentPaymentScanningFailedAlertViewModel)
    case bluetoothRequired(viewModel: PointOfSaleCardPresentPaymentBluetoothRequiredAlertViewModel)
    case foundReader(viewModel: PointOfSaleCardPresentPaymentFoundReaderAlertViewModel)
    case updatingReader(viewModel: CardPresentPaymentUpdatingReaderAlertViewModel)
    case updateFailed(viewModel: CardPresentPaymentReaderUpdateFailedAlertViewModel)
    case connectingToReader(viewModel: PointOfSaleCardPresentPaymentConnectingToReaderAlertViewModel)
    case connectingFailed(viewModel: PointOfSaleCardPresentPaymentConnectingFailedAlertViewModel)
    case connectingFailedNonRetryable(viewModel: PointOfSaleCardPresentPaymentConnectingFailedNonRetryableAlertViewModel)
    case connectingFailedChargeReader(viewModel: PointOfSaleCardPresentPaymentConnectingFailedChargeReaderAlertViewModel)
    case connectingFailedUpdateAddress(viewModel: PointOfSaleCardPresentPaymentConnectingFailedUpdateAddressAlertViewModel)
    case connectingFailedUpdatePostalCode(viewModel: PointOfSaleCardPresentPaymentConnectingFailedUpdatePostalCodeAlertViewModel)
}

extension CardPresentPaymentEventDetails {
    func toAlertType() -> PointOfSaleCardPresentPaymentAlertType? {
        switch self {
        case .scanningForReaders(let endSearch):
            return .scanningForReaders(
                viewModel: PointOfSaleCardPresentPaymentScanningForReadersAlertViewModel(endSearchAction: endSearch))

        case .scanningFailed(let error, let endSearch):
            return .scanningFailed(
                viewModel: PointOfSaleCardPresentPaymentScanningFailedAlertViewModel(
                    error: error,
                    endSearchAction: endSearch))

        case .bluetoothRequired(let error, let endSearch):
            return .bluetoothRequired(
                viewModel: PointOfSaleCardPresentPaymentBluetoothRequiredAlertViewModel(
                    error: error,
                    endSearch: endSearch))

        case .connectingToReader:
            return .connectingToReader(viewModel: PointOfSaleCardPresentPaymentConnectingToReaderAlertViewModel())

        case .connectingFailed(let error, let retrySearch, let endSearch):
            return .connectingFailed(
                viewModel: PointOfSaleCardPresentPaymentConnectingFailedAlertViewModel(
                    error: error,
                    retryButtonAction: retrySearch,
                    cancelButtonAction: endSearch))

        case .connectingFailedNonRetryable(let error, let endSearch):
            return .connectingFailedNonRetryable(
                viewModel: PointOfSaleCardPresentPaymentConnectingFailedNonRetryableAlertViewModel(
                    error: error,
                    cancelAction: endSearch))

        case .connectingFailedUpdatePostalCode(let retrySearch, let endSearch):
            return .connectingFailedUpdatePostalCode(
                viewModel: PointOfSaleCardPresentPaymentConnectingFailedUpdatePostalCodeAlertViewModel(
                    retryButtonAction: retrySearch,
                    cancelButtonAction: endSearch))

        case .connectingFailedChargeReader(let retrySearch, let endSearch):
            return .connectingFailedChargeReader(
                viewModel: PointOfSaleCardPresentPaymentConnectingFailedChargeReaderAlertViewModel(
                    retryButtonAction: retrySearch,
                    cancelButtonAction: endSearch))

        case .connectingFailedUpdateAddress(let wcSettingsAdminURL, let retrySearch, let endSearch):
            return .connectingFailedUpdateAddress(
                viewModel: PointOfSaleCardPresentPaymentConnectingFailedUpdateAddressAlertViewModel(
                    settingsAdminUrl: wcSettingsAdminURL,
                    retrySearchAction: retrySearch,
                    cancelSearchAction: endSearch))

        case .foundReader(let name, let connect, let continueSearch, let endSearch):
            return .foundReader(
                viewModel: PointOfSaleCardPresentPaymentFoundReaderAlertViewModel(
                    readerName: name,
                    connectAction: connect,
                    continueSearchAction: continueSearch,
                    endSearchAction: endSearch))

        case .updateProgress(let requiredUpdate, let progress, let cancelUpdate):
            return .updatingReader(viewModel: CardPresentPaymentUpdatingReaderAlertViewModel())

        case .updateFailed(let tryAgain, let cancelUpdate):
            return .updateFailed(viewModel: CardPresentPaymentReaderUpdateFailedAlertViewModel())

        case .updateFailedNonRetryable(let cancelUpdate):
            return .updateFailed(viewModel: CardPresentPaymentReaderUpdateFailedAlertViewModel())

        case .updateFailedLowBattery(let batteryLevel, let cancelUpdate):
            return .updateFailed(viewModel: CardPresentPaymentReaderUpdateFailedAlertViewModel())

            /// Payment messages are not handled as alerts, so should not be converted to alert view models
        case .preparingForPayment,
                .selectSearchType,
                .tapSwipeOrInsertCard,
                .success,
                .error,
                .errorNonRetryable,
                .processing,
                .displayReaderMessage,
                .cancelledOnReader,
                .validatingOrder:
            return nil
        }
    }
}
