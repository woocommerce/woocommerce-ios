import Foundation
import enum Yosemite.CardReaderServiceError
import enum Yosemite.CardReaderServiceUnderlyingError

enum CardPresentPaymentRetryApproach {
    case dontRetry
    case tryAgain(retryAction: () -> Void)
    case tryAnotherPaymentMethod(retryAction: () -> Void)

    init(error: any Error, retryAction: @escaping () -> Void) {
        guard let serviceError = error as? CardReaderServiceError else {
            self = .tryAgain(retryAction: retryAction)
            return
        }
        self = serviceError.retryApproach(with: retryAction)
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
