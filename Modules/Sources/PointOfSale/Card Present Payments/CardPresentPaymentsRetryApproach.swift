import Foundation
import enum Yosemite.CardReaderServiceError
import enum Yosemite.CardReaderServiceUnderlyingError

public enum CardPresentPaymentRetryApproach {
    case dontRetry
    case tryAgain(retryAction: () -> Void)
    case tryAnotherPaymentMethod(retryAction: () -> Void)

    public init(error: any Error, retryAction: @escaping () -> Void) {
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
                .softwareUpdate(underlyingError: let underlyingError, _),
                .reconnectionCancellation(underlyingError: let underlyingError):
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
                .bluetoothDenied,
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
                .tapToPayReaderTOSAcceptanceRequiresiCloudSignIn,
                .tapToPayReaderFailedToPrepare,
                .tapToPayReaderTOSAcceptanceCanceled,
                .tapToPayReaderTOSNotYetAccepted,
                .tapToPayReaderTOSAcceptanceFailed,
                .readerNotAccessibleInBackground,
                .commandNotAllowedDuringCall,
                .invalidAmount,
                .invalidCurrency,
                .cancelFailedAlreadyCompleted,
                .nilRefundPaymentMethod,
                .invalidRefundParameters,
                .invalidDiscoveryConfiguration,
                .invalidReaderForUpdate,
                .bluetoothConnectionInvalidLocationIdParameter,
                .invalidRequiredParameter,
                .invalidLocationIdParameter,
                .readerSoftwareUpdateFailedExpiredUpdate,
                .missingEMVData,
                .commandNotAllowed,
                .bluetoothPeerRemovedPairingInformation,
                .bluetoothAlreadyPairedWithAnotherDevice,
                .unknownReaderIpAddress,
                .internetConnectTimeOut,
                .bluetoothReconnectStarted,
                .tapToPayReaderAccountDeactivated,
                .readerMissingEncryptionKeys,
                .unexpectedReaderError,
                .commandRequiresCardholderConsent,
                .refundFailed,
                .cardSwipeNotAvailable,
                .interacNotSupportedOffline,
                .offlineAndCardExpired,
                .offlineTransactionDeclined,
                .offlineCollectAndConfirmMismatch,
                .onlinePinNotSupportedOffline,
                .offlineTestCardInLivemode,
                .stripeAPIResponseDecodingError,
                .internalNetworkError,
                .connectionTokenProviderCompletedWithError,
                .connectionTokenProviderTimedOut:
            return .tryAgain(retryAction: retryAction)
        case .paymentDeclinedByPaymentProcessorAPI,
                .paymentDeclinedByCardReader:
            return .tryAnotherPaymentMethod(retryAction: retryAction)
        case .alreadyConnectedToReader,
                .unsupportedSDK,
                .featureNotAvailableWithConnectedReader,
                .commandCancelled,
                .bluetoothLowEnergyUnsupported,
                .readerSessionExpired,
                .noRefundInProgress,
                .connectionAttemptInvalidated,
                .noActivePaymentIntent,
                .nfcDisabled,
                .tapToPayReaderMerchantBlocked,
                .tapToPayReaderInvalidMerchant,
                .tapToPayReaderDeviceBanned,
                .unsupportedMobileDeviceConfiguration,
                .readerIncompatible,
                .invalidClientSecret,
                .featureNotAvailable,
                .nilPaymentIntent,
                .nilSetupIntent,
                .forwardingTestModePaymentInLiveMode,
                .forwardingLiveModePaymentInTestMode,
                .readerConnectionConfigurationInvalid,
                .readerTippingParameterInvalid,
                .paymentMethodCollectionTimedOut:
            return .dontRetry
        }
    }
}
