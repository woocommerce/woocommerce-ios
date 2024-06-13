import Foundation

enum CardPresentPaymentAlertViewModel {
    case scanningForReaders(CardPresentPaymentScanningForReadersAlertViewModel)
    case scanningFailed(CardPresentPaymentScanningFailedAlertViewModel)
    case bluetoothRequired(CardPresentPaymentBluetoothRequiredAlertViewModel)

    case foundReader(CardPresentPaymentFoundReaderAlertViewModel)

    case updatingReader(CardPresentPaymentUpdatingReaderAlertViewModel)
    case updateFailed(CardPresentPaymentReaderUpdateFailedAlertViewModel)

    case connectingToReader(CardPresentPaymentConnectingToReaderAlertViewModel)
    case connectingFailed(CardPresentPaymentConnectingFailedAlertViewModel)

    case preparingForPayment(CardPresentPaymentPreparingForPaymentAlertViewModel)

    case tapSwipeOrInsertCard(CardPresentPaymentTapSwipeInsertCardAlertViewModel)

    case processing(CardPresentPaymentProcessingPaymentAlertViewModel)
    case displayReaderMessage(CardPresentPaymentDisplayReaderMessageAlertViewModel)

    case success(CardPresentPaymentSuccessAlertViewModel)

    case error(CardPresentPaymentErrorAlertViewModel)
}

extension CardPresentPaymentAlertDetails {
    func toAlertViewModel() -> CardPresentPaymentAlertViewModel {
        switch self {
        case .scanningForReaders(let endSearch):
                .scanningForReaders(CardPresentPaymentScanningForReadersAlertViewModel(endSearchAction: endSearch))

        case .scanningFailed(let error, let endSearch):
                .scanningFailed(CardPresentPaymentScanningFailedAlertViewModel(
                    error: error,
                    endSearchAction: endSearch))

        case .bluetoothRequired(let error, let endSearch):
                .bluetoothRequired(CardPresentPaymentBluetoothRequiredAlertViewModel(error: error, endSearch: endSearch))

        case .connectingToReader:
                .connectingToReader(CardPresentPaymentConnectingToReaderAlertViewModel())

        case .connectingFailed(let error, let retrySearch, let endSearch):
            .connectingFailed(CardPresentPaymentConnectingFailedAlertViewModel())

        case .connectingFailedNonRetryable(let error, let endSearch):
            .connectingFailed(CardPresentPaymentConnectingFailedAlertViewModel())

        case .connectingFailedUpdatePostalCode(let retrySearch, let endSearch),
                .connectingFailedChargeReader(let retrySearch, let endSearch):
            .connectingFailed(CardPresentPaymentConnectingFailedAlertViewModel())

        case .connectingFailedUpdateAddress(let wcSettingsAdminURL, let retrySearch, let endSearch):
            .connectingFailed(CardPresentPaymentConnectingFailedAlertViewModel())

        case .preparingForPayment(let cancelPayment):
                .preparingForPayment(CardPresentPaymentPreparingForPaymentAlertViewModel())

        case .selectSearchType(let tapToPay, let bluetooth, let endSearch):
                fatalError("Not supported")

        case .foundReader(let name, let connect, let continueSearch, let endSearch):
                .foundReader(CardPresentPaymentFoundReaderAlertViewModel(
                    readerName: name,
                    connectAction: connect,
                    continueSearchAction: continueSearch,
                    endSearchAction: endSearch))

        case .updateProgress(let requiredUpdate, let progress, let cancelUpdate):
                .updatingReader(CardPresentPaymentUpdatingReaderAlertViewModel())

        case .updateFailed(let tryAgain, let cancelUpdate):
                .updateFailed(CardPresentPaymentReaderUpdateFailedAlertViewModel())

        case .updateFailedNonRetryable(let cancelUpdate):
                .updateFailed(CardPresentPaymentReaderUpdateFailedAlertViewModel())

        case .updateFailedLowBattery(let batteryLevel, let cancelUpdate):
                .updateFailed(CardPresentPaymentReaderUpdateFailedAlertViewModel())

        case .tapSwipeOrInsertCard(let inputMethods, let cancelPayment):
                .tapSwipeOrInsertCard(CardPresentPaymentTapSwipeInsertCardAlertViewModel())

        case .success(let done):
                .success(CardPresentPaymentSuccessAlertViewModel())

        case .error(let error, let tryAgain, let cancelPayment):
                .error(CardPresentPaymentErrorAlertViewModel())

        case .errorNonRetryable(let error, let cancelPayment):
                .error(CardPresentPaymentErrorAlertViewModel())

        case .processing:
                .processing(CardPresentPaymentProcessingPaymentAlertViewModel())

        case .displayReaderMessage(let message):
                .displayReaderMessage(CardPresentPaymentDisplayReaderMessageAlertViewModel())

        case .cancelledOnReader:
                fatalError("Not supported")

        case .validatingOrder(let cancelPayment):
                .preparingForPayment(CardPresentPaymentPreparingForPaymentAlertViewModel())
        }
    }
}
