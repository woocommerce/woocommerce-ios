import Foundation

enum PointOfSaleCardPresentPaymentEventPresentationStyle {
    case message(PointOfSaleCardPresentPaymentMessageType)
    case alert(PointOfSaleCardPresentPaymentAlertType)

    struct Dependencies {
        let tryPaymentAgainBackToCheckoutAction: () -> Void
        let nonRetryableErrorExitAction: () -> Void
        let formattedOrderTotalPrice: String?
        let paymentCaptureErrorTryAgainAction: () -> Void
        let paymentCaptureErrorNewOrderAction: () -> Void
    }

    /// Determines the appropriate payment alert/message type and creates its view model.
    /// This init will fail for unsupported `CardPresentPaymentEventDetails` cases.
    ///
    /// - Parameters:
    ///   - cardPresentPaymentEventDetails: Provides the basis for the decision on the presentation style and view model creation.
    ///   In many cases, this is enough. These events are produced by the `CardPresentPaymentService`
    ///
    ///   - dependencies: Additional information which is considered when deciding the presentation style –
    ///   e.g. information about the order, or actions which don't originate from the payments code.
    ///   See `TotalsViewModel.observeCardPresentPaymentEvents` for an example.
    init?(for cardPresentPaymentEventDetails: CardPresentPaymentEventDetails,
          dependencies: Dependencies) {
        switch cardPresentPaymentEventDetails {
            /// Connection alerts
        case .scanningForReaders(let endSearch):
            self = .alert(.scanningForReaders(
                viewModel: PointOfSaleCardPresentPaymentScanningForReadersAlertViewModel(endSearchAction: endSearch)))

        case .scanningFailed(let error, let endSearch):
            self = .alert(.scanningFailed(
                viewModel: PointOfSaleCardPresentPaymentScanningFailedAlertViewModel(
                    error: error,
                    endSearchAction: endSearch)))

        case .bluetoothRequired(let error, let endSearch):
            self = .alert(.bluetoothRequired(
                viewModel: PointOfSaleCardPresentPaymentBluetoothRequiredAlertViewModel(
                    error: error,
                    endSearch: endSearch)))

        case .connectingToReader:
            self = .alert(.connectingToReader(viewModel: PointOfSaleCardPresentPaymentConnectingToReaderAlertViewModel()))

        case .connectingFailed(let error, let retrySearch, let endSearch):
            self = .alert(.connectingFailed(
                viewModel: PointOfSaleCardPresentPaymentConnectingFailedAlertViewModel(
                    error: error,
                    retryButtonAction: retrySearch,
                    cancelButtonAction: endSearch)))

        case .connectingFailedNonRetryable(let error, let endSearch):
            self = .alert(.connectingFailedNonRetryable(
                viewModel: PointOfSaleCardPresentPaymentConnectingFailedNonRetryableAlertViewModel(
                    error: error,
                    cancelAction: endSearch)))

        case .connectingFailedUpdatePostalCode(let retrySearch, let endSearch):
            self = .alert(.connectingFailedUpdatePostalCode(
                viewModel: PointOfSaleCardPresentPaymentConnectingFailedUpdatePostalCodeAlertViewModel(
                    retryButtonAction: retrySearch,
                    cancelButtonAction: endSearch)))

        case .connectingFailedChargeReader(let retrySearch, let endSearch):
            self = .alert(.connectingFailedChargeReader(
                viewModel: PointOfSaleCardPresentPaymentConnectingFailedChargeReaderAlertViewModel(
                    retryButtonAction: retrySearch,
                    cancelButtonAction: endSearch)))

        case .connectingFailedUpdateAddress(let wcSettingsAdminURL, let showsInAuthenticatedWebView, let retrySearch, let endSearch):
            self = .alert(.connectingFailedUpdateAddress(
                viewModel: PointOfSaleCardPresentPaymentConnectingFailedUpdateAddressAlertViewModel(
                    settingsAdminUrl: wcSettingsAdminURL,
                    showsInAuthenticatedWebView: showsInAuthenticatedWebView,
                    retrySearchAction: retrySearch,
                    cancelSearchAction: endSearch)))

        case .foundReader(let name, let connect, let continueSearch, let endSearch):
            self = .alert(.foundReader(
                viewModel: PointOfSaleCardPresentPaymentFoundReaderAlertViewModel(
                    readerName: name,
                    connectAction: connect,
                    continueSearchAction: continueSearch,
                    endSearchAction: endSearch)))

        case .foundMultipleReaders(let readerIDs, let selectionHandler):
            self = .alert(.foundMultipleReaders(
                viewModel: PointOfSaleCardPresentPaymentFoundMultipleReadersAlertViewModel(
                    readerIDs: readerIDs,
                    selectionHandler: selectionHandler)))

        case .updateProgress(let requiredUpdate, let progress, let cancelUpdate):
            if progress == 1.0 {
                self = .alert(.readerUpdateCompletion(viewModel: .init()))
            } else {
                self = requiredUpdate ?
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
            self = .alert(.updateFailed(
                viewModel: PointOfSaleCardPresentPaymentReaderUpdateFailedAlertViewModel(
                    retryAction: tryAgain,
                    cancelUpdateAction: cancelUpdate)))

        case .updateFailedNonRetryable(let cancelUpdate):
            self = .alert(.updateFailedNonRetryable(
                viewModel: PointOfSaleCardPresentPaymentReaderUpdateFailedNonRetryableAlertViewModel(
                    cancelUpdateAction: cancelUpdate)))

        case .updateFailedLowBattery(let batteryLevel, let cancelUpdate):
            self = .alert(.updateFailedLowBattery(
                viewModel: PointOfSaleCardPresentPaymentReaderUpdateFailedLowBatteryAlertViewModel(
                    batteryLevel: batteryLevel,
                    cancelUpdateAction: cancelUpdate)))

        case .connectionSuccess(let done):
            self = .alert(.connectionSuccess(
                viewModel: PointOfSaleCardPresentPaymentConnectionSuccessAlertViewModel(
                    doneAction: done)))

            /// Payment messages
        case .validatingOrder:
            self = .message(.validatingOrder(
                viewModel: PointOfSaleCardPresentPaymentValidatingOrderMessageViewModel()))
        case .preparingForPayment:
            self = .message(.preparingForPayment(
                viewModel: PointOfSaleCardPresentPaymentPreparingForPaymentMessageViewModel()))

        case .tapSwipeOrInsertCard(inputMethods: let inputMethods, cancelPayment: _):
            self = .message(.tapSwipeOrInsertCard(
                viewModel: PointOfSaleCardPresentPaymentTapSwipeInsertCardMessageViewModel(
                    inputMethods: inputMethods)))
        case .paymentSuccess:
            self = .message(.paymentSuccess(viewModel: PointOfSaleCardPresentPaymentSuccessMessageViewModel(
                formattedOrderTotal: dependencies.formattedOrderTotalPrice)))
        case .paymentError(error: let error, retryApproach: let retryApproach, _):
            switch error {
            case CollectOrderPaymentUseCaseError.couldNotRefreshOrder,
                CollectOrderPaymentUseCaseError.orderTotalChanged,
                CollectOrderPaymentUseCaseNotValidAmountError.belowMinimumAmount,
                CollectOrderPaymentUseCaseNotValidAmountError.other:
                self = .message(.validatingOrderError(viewModel: .init(error: error, retryApproach: retryApproach)))
            default:
                switch retryApproach {
                case .tryAnotherPaymentMethod(let retryAction):
                    self = .message(.paymentError(
                        viewModel: PointOfSaleCardPresentPaymentErrorMessageViewModel(
                            error: error,
                            tryAnotherPaymentMethodButtonAction: retryAction)))
                case .tryAgain(let retryAction):
                    self = .message(.paymentError(
                        viewModel: PointOfSaleCardPresentPaymentErrorMessageViewModel(
                            error: error,
                            tryPaymentAgainButtonAction: retryAction,
                            backToCheckoutButtonAction: dependencies.tryPaymentAgainBackToCheckoutAction)))
                case .dontRetry:
                    self = .message(.paymentErrorNonRetryable(
                        viewModel: PointOfSaleCardPresentPaymentNonRetryableErrorMessageViewModel(
                            error: error,
                            tryAnotherPaymentMethodAction: dependencies.nonRetryableErrorExitAction)))
                }
            }

        case .paymentCaptureError:
            self = .message(.paymentCaptureError(
                viewModel: PointOfSaleCardPresentPaymentCaptureErrorMessageViewModel(
                    tryAgainButtonAction: dependencies.paymentCaptureErrorTryAgainAction,
                    newOrderButtonAction: dependencies.paymentCaptureErrorNewOrderAction)))

        case .processing:
            self = .message(.processing(viewModel: PointOfSaleCardPresentPaymentProcessingMessageViewModel()))

        case .displayReaderMessage(message: let message):
            self = .message(.displayReaderMessage(
                viewModel: PointOfSaleCardPresentPaymentDisplayReaderMessageMessageViewModel(message: message)))

        case .cancelledOnReader:
            self = .message(.cancelledOnReader(
                viewModel: PointOfSaleCardPresentPaymentCancelledOnReaderMessageViewModel()))

            /// Not-yet supported types
        case .selectSearchType:
            return nil
        }
    }
}
