import Foundation

enum PointOfSaleCardPresentPaymentEventPresentationStyle {
    case message(PointOfSaleCardPresentPaymentMessageType)
    case alert(PointOfSaleCardPresentPaymentAlertType)
}

extension CardPresentPaymentEventDetails {
    var pointOfSalePresentationStyle: PointOfSaleCardPresentPaymentEventPresentationStyle? {
        switch self {
        /// Connection alerts
        case .scanningForReaders(let endSearch):
            return .alert(.scanningForReaders(
                viewModel: PointOfSaleCardPresentPaymentScanningForReadersAlertViewModel(endSearchAction: endSearch)))

        case .scanningFailed(let error, let endSearch):
            return .alert(.scanningFailed(
                viewModel: PointOfSaleCardPresentPaymentScanningFailedAlertViewModel(
                    error: error,
                    endSearchAction: endSearch)))

        case .bluetoothRequired(let error, let endSearch):
            return .alert(.bluetoothRequired(
                viewModel: PointOfSaleCardPresentPaymentBluetoothRequiredAlertViewModel(
                    error: error,
                    endSearch: endSearch)))

        case .connectingToReader:
            return .alert(.connectingToReader(viewModel: PointOfSaleCardPresentPaymentConnectingToReaderAlertViewModel()))

        case .connectingFailed(let error, let retrySearch, let endSearch):
            return .alert(.connectingFailed(
                viewModel: PointOfSaleCardPresentPaymentConnectingFailedAlertViewModel(
                    error: error,
                    retryButtonAction: retrySearch,
                    cancelButtonAction: endSearch)))

        case .connectingFailedNonRetryable(let error, let endSearch):
            return .alert(.connectingFailedNonRetryable(
                viewModel: PointOfSaleCardPresentPaymentConnectingFailedNonRetryableAlertViewModel(
                    error: error,
                    cancelAction: endSearch)))

        case .connectingFailedUpdatePostalCode(let retrySearch, let endSearch):
            return .alert(.connectingFailedUpdatePostalCode(
                viewModel: PointOfSaleCardPresentPaymentConnectingFailedUpdatePostalCodeAlertViewModel(
                    retryButtonAction: retrySearch,
                    cancelButtonAction: endSearch)))

        case .connectingFailedChargeReader(let retrySearch, let endSearch):
            return .alert(.connectingFailedChargeReader(
                viewModel: PointOfSaleCardPresentPaymentConnectingFailedChargeReaderAlertViewModel(
                    retryButtonAction: retrySearch,
                    cancelButtonAction: endSearch)))

        case .connectingFailedUpdateAddress(let wcSettingsAdminURL, let retrySearch, let endSearch):
            return .alert(.connectingFailedUpdateAddress(
                viewModel: PointOfSaleCardPresentPaymentConnectingFailedUpdateAddressAlertViewModel(
                    settingsAdminUrl: wcSettingsAdminURL,
                    retrySearchAction: retrySearch,
                    cancelSearchAction: endSearch)))

        case .foundReader(let name, let connect, let continueSearch, let endSearch):
            return .alert(.foundReader(
                viewModel: PointOfSaleCardPresentPaymentFoundReaderAlertViewModel(
                    readerName: name,
                    connectAction: connect,
                    continueSearchAction: continueSearch,
                    endSearchAction: endSearch)))

        case .updateProgress(let requiredUpdate, let progress, let cancelUpdate):
            return .alert(.updatingReader(viewModel: CardPresentPaymentUpdatingReaderAlertViewModel()))

        case .updateFailed(let tryAgain, let cancelUpdate):
            return .alert(.updateFailed(viewModel: CardPresentPaymentReaderUpdateFailedAlertViewModel()))

        case .updateFailedNonRetryable(let cancelUpdate):
            return .alert(.updateFailed(viewModel: CardPresentPaymentReaderUpdateFailedAlertViewModel()))

        case .updateFailedLowBattery(let batteryLevel, let cancelUpdate):
            return .alert(.updateFailed(viewModel: CardPresentPaymentReaderUpdateFailedAlertViewModel()))

        /// Payment messages
        case .preparingForPayment(cancelPayment: let cancelPayment):
            return .message(.preparingForPayment(
                viewModel: PointOfSaleCardPresentPaymentPreparingForPaymentMessageViewModel(
                    cancelAction: cancelPayment)))

        case .tapSwipeOrInsertCard(inputMethods: let inputMethods, cancelPayment: let cancelPayment):
            return .message(.tapSwipeOrInsertCard(
                viewModel: PointOfSaleCardPresentPaymentTapSwipeInsertCardMessageViewModel(
                    inputMethods: inputMethods,
                    cancelAction: cancelPayment)))

        case .paymentSuccess(done: let done):
            return .message(.paymentSuccess(viewModel: PointOfSaleCardPresentPaymentSuccessMessageViewModel()))

        case .paymentError(error: let error, tryAgain: let tryAgain, cancelPayment: let cancelPayment):
            return .message(.paymentError(
                viewModel: PointOfSaleCardPresentPaymentErrorMessageViewModel(
                    error: error,
                    tryAgainButtonAction: tryAgain,
                    cancelButtonAction: cancelPayment)))

        case .paymentErrorNonRetryable(error: let error, cancelPayment: let cancelPayment):
            return .message(.paymentErrorNonRetryable(
                viewModel: PointOfSaleCardPresentPaymentNonRetryableErrorMessageViewModel()))

        case .processing:
            return .message(.processing(viewModel: PointOfSaleCardPresentPaymentProcessingMessageViewModel()))

        case .displayReaderMessage(message: let message):
            return .message(.displayReaderMessage(
                viewModel: PointOfSaleCardPresentPaymentDisplayReaderMessageMessageViewModel(message: message)))

        case .cancelledOnReader:
            return .message(.cancelledOnReader(
                viewModel: PointOfSaleCardPresentPaymentCancelledOnReaderMessageViewModel()))

        /// Not-yet supported types
        case .selectSearchType,
                .validatingOrder:
            return nil
        }
    }
}
