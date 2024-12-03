#if !targetEnvironment(macCatalyst)
import StripeTerminal
/// Maps Stripe SDK specific errors to domain errors:
/// the mapping is done according to the error codes documented here:
/// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html
extension UnderlyingError {
    init?(withStripeError stripeError: Error) {
        let error = stripeError as NSError
        guard error.domain == ErrorDomain else {
            return nil
        }

        if let stripeError = StripeTerminal.ErrorCode.Code(rawValue: error.code) {
            switch stripeError {
            case .notConnectedToReader:
                self = .notConnectedToReader
            case .alreadyConnectedToReader:
                self = .alreadyConnectedToReader
            case .confirmInvalidPaymentIntent:
                self = .confirmInvalidPaymentIntent
            case .unsupportedSDK:
                self = .unsupportedSDK
            case .featureNotAvailableWithConnectedReader:
                self = .featureNotAvailableWithConnectedReader
            case .canceled:
                self = .commandCancelled(from: .unknown)
            case .locationServicesDisabled:
                self = .locationServicesDisabled
            case .bluetoothDisabled:
                self = .bluetoothDisabled
            case .bluetoothError:
                self = .bluetoothError
            case .bluetoothScanTimedOut:
                self = .bluetoothScanTimedOut
            case .bluetoothLowEnergyUnsupported:
                self = .bluetoothLowEnergyUnsupported
            case .bluetoothConnectionFailedBatteryCriticallyLow:
                self = .bluetoothConnectionFailedBatteryCriticallyLow
            case .readerSoftwareUpdateFailedBatteryLow:
                self = .readerSoftwareUpdateFailedBatteryLow
            case .readerSoftwareUpdateFailedInterrupted:
                self = .readerSoftwareUpdateFailedInterrupted
            case .readerSoftwareUpdateFailed:
                self = .readerSoftwareUpdateFailed
            case .readerSoftwareUpdateFailedReaderError:
                self = .readerSoftwareUpdateFailedReader
            case .readerSoftwareUpdateFailedServerError:
                self = .readerSoftwareUpdateFailedServer
            case .cardInsertNotRead:
                self = .cardInsertNotRead
            case .cardSwipeNotRead:
                self = .cardSwipeNotRead
            case .cardReadTimedOut:
                self = .cardReadTimeOut
            case .cardRemoved:
                self = .cardRemoved
            case .cardLeftInReader:
                self = .cardLeftInReader
            case .readerBusy:
                self = .readerBusy
            case .incompatibleReader:
                self = .readerIncompatible
            case .readerCommunicationError:
                self = .readerCommunicationError
            case .bluetoothConnectTimedOut:
                self = .bluetoothConnectTimedOut
            case .bluetoothDisconnected:
                self = .bluetoothDisconnected
            case .unsupportedReaderVersion:
                self = .unsupportedReaderVersion
            case .connectFailedReaderIsInUse:
                self = .connectFailedReaderIsInUse
            case .unexpectedSdkError:
                self = .unexpectedSDKError
            case .declinedByStripeAPI:
                // https://stripe.dev/stripe-terminal-ios/docs/Errors.html#/c:@SCPErrorKeyStripeAPIDeclineCode
                let declineCode = error.userInfo[ErrorKey.stripeAPIDeclineCode.rawValue] as? String
                let declineReason = DeclineReason(with: declineCode ?? "")
                self = .paymentDeclinedByPaymentProcessorAPI(declineReason: declineReason)
            case .declinedByReader:
                self = .paymentDeclinedByCardReader
            case .notConnectedToInternet:
                self = .notConnectedToInternet
            case .requestTimedOut:
                self = .requestTimedOut
            case .sessionExpired:
                self = .readerSessionExpired
            case .stripeAPIError:
                self = .processorAPIError
            case .passcodeNotEnabled:
                self = .passcodeNotEnabled
            case .appleBuiltInReaderTOSAcceptanceRequiresiCloudSignIn:
                self = .appleBuiltInReaderTOSAcceptanceRequiresiCloudSignIn
            case .nfcDisabled:
                self = .nfcDisabled
            case .appleBuiltInReaderFailedToPrepare:
                self = .appleBuiltInReaderFailedToPrepare
            case .appleBuiltInReaderTOSAcceptanceCanceled:
                self = .appleBuiltInReaderTOSAcceptanceCanceled
            case .appleBuiltInReaderTOSNotYetAccepted:
                self = .appleBuiltInReaderTOSNotYetAccepted
            case .appleBuiltInReaderTOSAcceptanceFailed:
                self = .appleBuiltInReaderTOSAcceptanceFailed
            case .appleBuiltInReaderMerchantBlocked:
                self = .appleBuiltInReaderMerchantBlocked
            case .appleBuiltInReaderInvalidMerchant:
                self = .appleBuiltInReaderInvalidMerchant
            case .appleBuiltInReaderDeviceBanned:
                self = .appleBuiltInReaderDeviceBanned
            case .unsupportedMobileDeviceConfiguration:
                self = .unsupportedMobileDeviceConfiguration
            case .readerNotAccessibleInBackground:
                self = .readerNotAccessibleInBackground
            case .commandNotAllowedDuringCall:
                self = .commandNotAllowedDuringCall
            case .invalidAmount:
                self = .invalidAmount
            case .invalidCurrency:
                self = .invalidCurrency
            case .cancelFailedAlreadyCompleted:
                self = .cancelFailedAlreadyCompleted
            case .nilPaymentIntent:
                self = .nilPaymentIntent
            case .nilSetupIntent:
                self = .nilSetupIntent
            case .nilRefundPaymentMethod:
                self = .nilRefundPaymentMethod
            case .invalidRefundParameters:
                self = .invalidRefundParameters
            case .invalidClientSecret:
                self = .invalidClientSecret
            case .invalidDiscoveryConfiguration:
                self = .invalidDiscoveryConfiguration
            case .invalidReaderForUpdate:
                self = .invalidReaderForUpdate
            case .featureNotAvailable:
                self = .featureNotAvailable
            case .bluetoothConnectionInvalidLocationIdParameter:
                self = .bluetoothConnectionInvalidLocationIdParameter
            case .invalidRequiredParameter:
                self = .invalidRequiredParameter
            case .forwardingTestModePaymentInLiveMode:
                self = .forwardingTestModePaymentInLiveMode
            case .forwardingLiveModePaymentInTestMode:
                self = .forwardingLiveModePaymentInTestMode
            case .readerConnectionConfigurationInvalid:
                self = .readerConnectionConfigurationInvalid
            case .readerTippingParameterInvalid:
                self = .readerTippingParameterInvalid
            case .invalidLocationIdParameter:
                self = .invalidLocationIdParameter
            case .bluetoothAccessDenied:
                self = .bluetoothDenied
            case .readerSoftwareUpdateFailedExpiredUpdate:
                self = .readerSoftwareUpdateFailedExpiredUpdate
            case .missingEMVData:
                self = .missingEMVData
            case .commandNotAllowed:
                self = .commandNotAllowed
            case .bluetoothPeerRemovedPairingInformation:
                self = .bluetoothPeerRemovedPairingInformation
            case .bluetoothAlreadyPairedWithAnotherDevice:
                self = .bluetoothAlreadyPairedWithAnotherDevice
            case .unknownReaderIpAddress:
                self = .unknownReaderIpAddress
            case .internetConnectTimeOut:
                self = .internetConnectTimeOut
            case .bluetoothReconnectStarted:
                self = .bluetoothReconnectStarted
            case .appleBuiltInReaderAccountDeactivated:
                self = .appleBuiltInReaderAccountDeactivated
            case .readerMissingEncryptionKeys:
                self = .readerMissingEncryptionKeys
            case .unexpectedReaderError:
                self = .unexpectedReaderError
            case .commandRequiresCardholderConsent:
                self = .commandRequiresCardholderConsent
            case .refundFailed:
                self = .refundFailed
            case .cardSwipeNotAvailable:
                self = .cardSwipeNotAvailable
            case .interacNotSupportedOffline:
                self = .interacNotSupportedOffline
            case .offlineAndCardExpired:
                self = .offlineAndCardExpired
            case .offlineTransactionDeclined:
                self = .offlineTransactionDeclined
            case .offlineCollectAndConfirmMismatch:
                self = .offlineCollectAndConfirmMismatch
            case .onlinePinNotSupportedOffline:
                self = .onlinePinNotSupportedOffline
            case .offlineTestCardInLivemode:
                self = .offlineTestCardInLivemode
            case .stripeAPIResponseDecodingError:
                self = .stripeAPIResponseDecodingError
            case .internalNetworkError:
                self = .internalNetworkError
            case .connectionTokenProviderCompletedWithError:
                self = .connectionTokenProviderCompletedWithError
            case .connectionTokenProviderTimedOut:
                self = .connectionTokenProviderTimedOut
            /// Our `DefaultConnectionTokenProvider` implementation of `fetchConnectionToken` never calls completion block with `(nil, nil)`.
            case .connectionTokenProviderCompletedWithNothing,
                /// Offline mode is not supported.
                .connectionTokenProviderCompletedWithNothingWhileForwarding,
                .accountIdMismatchWhileForwarding,
                .updatePaymentIntentUnavailableWhileOffline,
                .updatePaymentIntentUnavailableWhileOfflineModeEnabled,
                .offlinePaymentsDatabaseTooLarge,
                .readerConnectionOfflinePairingUnseenDisabled,
                .noLastSeenAccount,
                .connectionTokenProviderCompletedWithErrorWhileForwarding,
                .offlineBehaviorForceOfflineWithFeatureDisabled,
                .readerConnectionNotAvailableOffline,
                .readerConnectionOfflineLocationMismatch,
                .readerConnectionOfflineNeedsUpdate,
                .amountExceedsMaxOfflineAmount,
                .invalidOfflineCurrency,
                .encryptionKeyFailure,
                .encryptionKeyStillInitializing,
                .notConnectedToInternetAndOfflineBehaviorRequireOnline,
                /// We don’t request a list of locations directly, but request the store location instead.
                .invalidListLocationsLimitParameter,
                /// `on_behalf_of` parameter is not set in the payment intent.
                .invalidRequiredParameterOnBehalfOf,
                /// Dynamic currency conversion not supported.
                .requestDynamicCurrencyConversionRequiresUpdatePaymentIntent,
                .dynamicCurrencyConversionNotAvailable,
                /// Surcharging is not supported.
                .surchargingNotAvailable,
                .surchargeNoticeRequiresUpdatePaymentIntent,
                .surchargeUnavailableWithDynamicCurrencyConversion,
                /// Collecting on-screen inputs from card reader is not supported.
                .collectInputsInvalidParameter,
                .collectInputsUnsupported,
                .collectInputsTimedOut,
                .collectInputsApplicationError,
                /// USB discovery is not supported.
                .usbDiscoveryTimedOut,
                .usbDisconnected:
                assertionFailure("Unexpected Stripe error that we should consider handling: \(stripeError)")
                return nil
            }
        }

        return nil
    }
}
#endif
