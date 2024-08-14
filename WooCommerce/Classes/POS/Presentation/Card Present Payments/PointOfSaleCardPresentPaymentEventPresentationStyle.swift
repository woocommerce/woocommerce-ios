import Foundation

enum PointOfSaleCardPresentPaymentEventPresentationStyle {
    case message(PointOfSaleCardPresentPaymentMessageType)
    case alert(PointOfSaleCardPresentPaymentAlertType)
}

/// View Models are created in this short-lived factory, so we can provide information beyond what's available from  `CardPresentPaymentEventDetails`
/// See `TotalsViewModel.observeCardPresentPaymentEvents` for an example.
struct PointOfSaleCardPresentPaymentEventPresentationStyleDeterminer {
    let cancelThenCollectPaymentAction: () -> Void
    let formattedOrderTotalPrice: String?

    func pointOfSalePresentationStyle(for eventDetails: CardPresentPaymentEventDetails) -> PointOfSaleCardPresentPaymentEventPresentationStyle? {
        switch eventDetails {
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

        case .connectingFailedUpdateAddress(let wcSettingsAdminURL, let showsInAuthenticatedWebView, let retrySearch, let endSearch):
            return .alert(.connectingFailedUpdateAddress(
                viewModel: PointOfSaleCardPresentPaymentConnectingFailedUpdateAddressAlertViewModel(
                    settingsAdminUrl: wcSettingsAdminURL,
                    showsInAuthenticatedWebView: showsInAuthenticatedWebView,
                    retrySearchAction: retrySearch,
                    cancelSearchAction: endSearch)))

        case .foundReader(let name, let connect, let continueSearch, let endSearch):
            return .alert(.foundReader(
                viewModel: PointOfSaleCardPresentPaymentFoundReaderAlertViewModel(
                    readerName: name,
                    connectAction: connect,
                    continueSearchAction: continueSearch,
                    endSearchAction: endSearch)))

        case .foundMultipleReaders(let readerIDs, let selectionHandler):
            return .alert(.foundMultipleReaders(
                viewModel: PointOfSaleCardPresentPaymentFoundMultipleReadersAlertViewModel(
                    readerIDs: readerIDs,
                    selectionHandler: selectionHandler)))

        case .updateProgress(let requiredUpdate, let progress, let cancelUpdate):
                if progress == 1.0 {
                    return .alert(.readerUpdateCompletion(viewModel: .init()))
                } else {
                    return requiredUpdate ?
                        .alert(.requiredReaderUpdateInProgress(
                            viewModel: PointOfSaleCardPresentPaymentRequiredReaderUpdateInProgressAlertViewModel(
                                progress: progress,
                                cancel: cancelUpdate))) :
                        .alert(.optionalReaderUpdateInProgress(
                            viewModel: PointOfSaleCardPresentPaymentOptionalReaderUpdateInProgressAlertViewModel(
                                progress: progress,
                                cancel: cancelUpdate)))

                }

        case .updateFailed(let tryAgain, let cancelUpdate):
            return .alert(.updateFailed(
                viewModel: PointOfSaleCardPresentPaymentReaderUpdateFailedAlertViewModel(
                    retryAction: tryAgain,
                    cancelUpdateAction: cancelUpdate)))

        case .updateFailedNonRetryable(let cancelUpdate):
            return .alert(.updateFailedNonRetryable(
                viewModel: PointOfSaleCardPresentPaymentReaderUpdateFailedNonRetryableAlertViewModel(
                    cancelUpdateAction: cancelUpdate)))

        case .updateFailedLowBattery(let batteryLevel, let cancelUpdate):
            return .alert(.updateFailedLowBattery(
                viewModel: PointOfSaleCardPresentPaymentReaderUpdateFailedLowBatteryAlertViewModel(
                    batteryLevel: batteryLevel,
                    cancelUpdateAction: cancelUpdate)))

        case .connectionSuccess(let done):
            return .alert(.connectionSuccess(
                viewModel: PointOfSaleCardPresentPaymentConnectionSuccessAlertViewModel(
                    doneAction: done)))

        /// Payment messages
        case .validatingOrder:
            return .message(.validatingOrder(
                viewModel: PointOfSaleCardPresentPaymentValidatingOrderMessageViewModel()))
        case .preparingForPayment:
            return .message(.preparingForPayment(
                viewModel: PointOfSaleCardPresentPaymentPreparingForPaymentMessageViewModel()))

        case .tapSwipeOrInsertCard(inputMethods: let inputMethods, cancelPayment: _):
            return .message(.tapSwipeOrInsertCard(
                viewModel: PointOfSaleCardPresentPaymentTapSwipeInsertCardMessageViewModel(
                    inputMethods: inputMethods)))
        case .paymentSuccess:
            return .message(.paymentSuccess(viewModel: PointOfSaleCardPresentPaymentSuccessMessageViewModel(formattedOrderTotal: formattedOrderTotalPrice)))
        case .paymentError(error: let error, retryApproach: let retryApproach, _):
            switch error {
            case CollectOrderPaymentUseCaseError.couldNotRefreshOrder,
                CollectOrderPaymentUseCaseError.orderTotalChanged,
                CollectOrderPaymentUseCaseNotValidAmountError.belowMinimumAmount,
                CollectOrderPaymentUseCaseNotValidAmountError.other:
                return .message(.validatingOrderError(viewModel: .init(error: error, retryApproach: retryApproach)))
            default:
                switch retryApproach {
                case .tryAnotherPaymentMethod(let retryAction):
                    return .message(.paymentError(
                        viewModel: PointOfSaleCardPresentPaymentErrorMessageViewModel(
                            error: error,
                            tryAnotherPaymentMethodButtonAction: retryAction)))
                case .tryAgain(let retryAction):
                    return .message(.paymentError(
                        viewModel: PointOfSaleCardPresentPaymentErrorMessageViewModel(
                            error: error,
                            tryPaymentAgainButtonAction: retryAction,
                            backToCheckoutButtonAction: cancelThenCollectPaymentAction)))
                case .dontRetry:
                    return .message(.paymentErrorNonRetryable(
                        viewModel: PointOfSaleCardPresentPaymentNonRetryableErrorMessageViewModel(
                            error: error,
                            tryAnotherPaymentMethodAction: cancelThenCollectPaymentAction)))
                }
            }
        case .paymentCaptureError(let cancelPayment):
            return .message(.paymentCaptureError(
                viewModel: PointOfSaleCardPresentPaymentCaptureErrorMessageViewModel(cancelButtonAction: cancelPayment)))

        case .processing:
            return .message(.processing(viewModel: PointOfSaleCardPresentPaymentProcessingMessageViewModel()))

        case .displayReaderMessage(message: let message):
            return .message(.displayReaderMessage(
                viewModel: PointOfSaleCardPresentPaymentDisplayReaderMessageMessageViewModel(message: message)))

        case .cancelledOnReader:
            return .message(.cancelledOnReader(
                viewModel: PointOfSaleCardPresentPaymentCancelledOnReaderMessageViewModel()))

        /// Not-yet supported types
        case .selectSearchType:
            return nil
        }
    }
}
