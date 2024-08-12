import Foundation
import struct Yosemite.CardReaderInput
import enum Yosemite.CardReaderServiceError
import enum Yosemite.CardReaderServiceUnderlyingError

struct CardPresentPaymentsTransactionAlertsProvider: CardReaderTransactionAlertsProviding {
    typealias AlertDetails = CardPresentPaymentEventDetails

    func validatingOrder(onCancel: @escaping () -> Void) -> CardPresentPaymentEventDetails {
        .validatingOrder(cancelPayment: onCancel)
    }

    func preparingReader(onCancel: @escaping () -> Void) -> CardPresentPaymentEventDetails {
        .preparingForPayment(cancelPayment: onCancel)
    }

    func tapOrInsertCard(title: String,
                         amount: String,
                         inputMethods: CardReaderInput,
                         onCancel: @escaping () -> Void) -> CardPresentPaymentEventDetails {
        .tapSwipeOrInsertCard(inputMethods: inputMethods,
                              cancelPayment: onCancel)
    }

    func displayReaderMessage(message: String) -> CardPresentPaymentEventDetails {
        .displayReaderMessage(message: message)
    }

    func processingTransaction(title: String) -> CardPresentPaymentEventDetails {
        .processing
    }

    func success(printReceipt: @escaping () -> Void,
                 emailReceipt: @escaping () -> Void,
                 noReceiptAction: @escaping () -> Void) -> CardPresentPaymentEventDetails {
        .paymentSuccess(done: noReceiptAction)
    }

    func error(error: any Error,
               tryAgain: @escaping () -> Void,
               dismissCompletion: @escaping () -> Void) -> CardPresentPaymentEventDetails {
        .paymentError(error: error,
                      retryApproach: retryApproach(for: error, retryAction: tryAgain),
                      cancelPayment: dismissCompletion)
    }

    func nonRetryableError(error: any Error,
                           dismissCompletion: @escaping () -> Void) -> CardPresentPaymentEventDetails {
        .paymentError(error: error,
                      retryApproach: .dontRetry,
                      cancelPayment: dismissCompletion)
    }

    func cancelledOnReader() -> CardPresentPaymentEventDetails? {
        .cancelledOnReader
    }
}

private extension CardPresentPaymentsTransactionAlertsProvider {
    func retryApproach(for error: any Error,
                       retryAction: @escaping () -> Void) -> CardPresentPaymentRetryApproach {
        guard let serviceError = error as? CardReaderServiceError else {
            return .tryAgain(retryAction: retryAction)
        }
        return serviceError.retryApproach(with: retryAction)
    }
}

private extension CardReaderServiceError {
    func retryApproach(with retryAction: @escaping () -> Void) -> CardPresentPaymentRetryApproach {
        switch self {
        case .discovery(underlyingError: let underlyingError),
                .connection(underlyingError: let underlyingError),
                .disconnection(underlyingError: let underlyingError),
                .intentCreation(underlyingError: let underlyingError),
                .paymentMethodCollection(underlyingError: let underlyingError),
                .paymentCapture(underlyingError: let underlyingError),
                .paymentCaptureWithPaymentMethod(underlyingError: let underlyingError, _),
                .paymentCancellation(underlyingError: let underlyingError),
                .refundCreation(underlyingError: let underlyingError),
                .refundCancellation(underlyingError: let underlyingError),
                .softwareUpdate(underlyingError: let underlyingError, _):
            return underlyingError.retryApproach(with: retryAction)
        case .refundPayment(underlyingError: let underlyingError, shouldRetry: let shouldRetry):
            guard shouldRetry else {
                return .dontRetry
            }
            return underlyingError.retryApproach(with: retryAction)
        case .bluetoothDenied:
            return .tryAgain(retryAction: retryAction)
        case .retryNotPossibleNoActivePayment,
                .retryNotPossibleActivePaymentCancelled,
                .retryNotPossibleActivePaymentSucceeded,
                .retryNotPossibleProcessingInProgress,
                .retryNotPossibleRequiresAction,
                .retryNotPossibleUnknownCause:
            return .dontRetry
        }
    }
}

private extension CardReaderServiceUnderlyingError {
    func retryApproach(with retryAction: @escaping () -> Void) -> CardPresentPaymentRetryApproach {
        switch self {
        case .notConnectedToReader,
                .confirmInvalidPaymentIntent,
                .locationServicesDisabled,
                .bluetoothDisabled,
                .bluetoothError,
                .bluetoothScanTimedOut,
                .bluetoothConnectionFailedBatteryCriticallyLow,
                .readerSoftwareUpdateFailedBatteryLow,
                .readerSoftwareUpdateFailedInterrupted,
                .readerSoftwareUpdateFailed,
                .readerSoftwareUpdateFailedReader,
                .readerSoftwareUpdateFailedServer,
                .cardInsertNotRead,
                .cardSwipeNotRead,
                .cardReadTimeOut,
                .cardRemoved,
                .cardLeftInReader,
                .readerBusy,
                .readerCommunicationError,
                .bluetoothConnectTimedOut,
                .bluetoothDisconnected,
                .unsupportedReaderVersion,
                .connectFailedReaderIsInUse,
                .unexpectedSDKError,
                .notConnectedToInternet,
                .requestTimedOut,
                .processorAPIError,
                .internalServiceError,
                .incompleteStoreAddress,
                .invalidPostalCode,
                .passcodeNotEnabled,
                .appleBuiltInReaderTOSAcceptanceRequiresiCloudSignIn,
                .appleBuiltInReaderFailedToPrepare,
                .appleBuiltInReaderTOSAcceptanceCanceled,
                .appleBuiltInReaderTOSNotYetAccepted,
                .appleBuiltInReaderTOSAcceptanceFailed,
                .readerNotAccessibleInBackground,
                .commandNotAllowedDuringCall,
                .invalidAmount,
                .invalidCurrency:
            return .tryAgain(retryAction: retryAction)
        case .paymentDeclinedByPaymentProcessorAPI,
                .paymentDeclinedByCardReader:
            return .tryAnotherPaymentMethod(retryAction: retryAction)
        case .alreadyConnectedToReader,
                .unsupportedSDK,
                .commandCancelled,
                .bluetoothLowEnergyUnsupported,
                .readerSessionExpired,
                .noRefundInProgress,
                .connectionAttemptInvalidated,
                .noActivePaymentIntent,
                .nfcDisabled,
                .appleBuiltInReaderMerchantBlocked,
                .appleBuiltInReaderInvalidMerchant,
                .appleBuiltInReaderDeviceBanned,
                .unsupportedMobileDeviceConfiguration,
                .featureNotAvailableWithConnectedReader,
                .readerIncompatible:
            return .dontRetry
        }
    }
}
