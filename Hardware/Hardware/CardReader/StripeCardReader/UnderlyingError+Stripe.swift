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
            case .connectionTokenProviderCompletedWithNothing:
                self = .connectionTokenProviderCompletedWithNothing
            case .connectionTokenProviderCompletedWithNothingWhileForwarding:
                self = .connectionTokenProviderCompletedWithNothingWhileForwarding
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
            case .invalidListLocationsLimitParameter:
                self = .invalidListLocationsLimitParameter
            case .bluetoothConnectionInvalidLocationIdParameter:
                self = .bluetoothConnectionInvalidLocationIdParameter
            case .invalidRequiredParameter:
                self = .invalidRequiredParameter
            case .invalidRequiredParameterOnBehalfOf:
                self = .invalidRequiredParameterOnBehalfOf
            case .accountIdMismatchWhileForwarding:
                self = .accountIdMismatchWhileForwarding
            case .updatePaymentIntentUnavailableWhileOffline:
                self = .updatePaymentIntentUnavailableWhileOffline
            case .updatePaymentIntentUnavailableWhileOfflineModeEnabled:
                self = .updatePaymentIntentUnavailableWhileOfflineModeEnabled
            case .forwardingTestModePaymentInLiveMode:
                self = .forwardingTestModePaymentInLiveMode
            case .forwardingLiveModePaymentInTestMode:
                self = .forwardingLiveModePaymentInTestMode
            case .readerConnectionConfigurationInvalid:
                self = .readerConnectionConfigurationInvalid
            case .requestDynamicCurrencyConversionRequiresUpdatePaymentIntent:
                self = .requestDynamicCurrencyConversionRequiresUpdatePaymentIntent
            case .dynamicCurrencyConversionNotAvailable:
                self = .dynamicCurrencyConversionNotAvailable
            case .surchargingNotAvailable:
                self = .surchargingNotAvailable
            case .readerTippingParameterInvalid:
                self = .readerTippingParameterInvalid
            case .surchargeNoticeRequiresUpdatePaymentIntent:
                self = .surchargeNoticeRequiresUpdatePaymentIntent
            case .surchargeUnavailableWithDynamicCurrencyConversion:
                self = .surchargeUnavailableWithDynamicCurrencyConversion
            case .invalidLocationIdParameter:
                self = .invalidLocationIdParameter
            case .collectInputsInvalidParameter:
                self = .collectInputsInvalidParameter
            case .collectInputsUnsupported:
                self = .collectInputsUnsupported
            case .bluetoothAccessDenied:
                self = .bluetoothAccessDenied
            case .readerSoftwareUpdateFailedExpiredUpdate:
                self = .readerSoftwareUpdateFailedExpiredUpdate
            case .offlinePaymentsDatabaseTooLarge:
                self = .offlinePaymentsDatabaseTooLarge
            case .readerConnectionNotAvailableOffline:
                self = .readerConnectionNotAvailableOffline
            case .readerConnectionOfflineLocationMismatch:
                self = .readerConnectionOfflineLocationMismatch
            case .readerConnectionOfflineNeedsUpdate:
                self = .readerConnectionOfflineNeedsUpdate
            case .readerConnectionOfflinePairingUnseenDisabled:
                self = .readerConnectionOfflinePairingUnseenDisabled
            case .noLastSeenAccount:
                self = .noLastSeenAccount
            case .amountExceedsMaxOfflineAmount:
                self = .amountExceedsMaxOfflineAmount
            case .invalidOfflineCurrency:
                self = .invalidOfflineCurrency
            case .missingEMVData:
                self = .missingEMVData
            case .commandNotAllowed:
                self = .commandNotAllowed
            case .collectInputsTimedOut:
                self = .collectInputsTimedOut
            case .usbDiscoveryTimedOut:
                self = .usbDiscoveryTimedOut
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
            case .usbDisconnected:
                self = .usbDisconnected
            case .unexpectedReaderError:
                self = .unexpectedReaderError
            case .encryptionKeyFailure:
                self = .encryptionKeyFailure
            case .encryptionKeyStillInitializing:
                self = .encryptionKeyStillInitializing
            case .collectInputsApplicationError:
                self = .collectInputsApplicationError
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
            case .connectionTokenProviderCompletedWithErrorWhileForwarding:
                self = .connectionTokenProviderCompletedWithErrorWhileForwarding
            case .connectionTokenProviderTimedOut:
                self = .connectionTokenProviderTimedOut
            case .notConnectedToInternetAndOfflineBehaviorRequireOnline:
                self = .notConnectedToInternetAndOfflineBehaviorRequireOnline
            case .offlineBehaviorForceOfflineWithFeatureDisabled:
                self = .offlineBehaviorForceOfflineWithFeatureDisabled
            @unknown default:
                return nil
            }
        }

        return nil
    }
}
#endif
