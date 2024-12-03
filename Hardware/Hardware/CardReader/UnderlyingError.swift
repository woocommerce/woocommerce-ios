/// Underlying error. Models the specific error that made a given
/// interaction with the SDK fail.
public enum UnderlyingError: Error, Equatable {
    /// No reader is connected. Connect to a reader before trying again.
    case notConnectedToReader

    /// Already connected to a reader.
    case alreadyConnectedToReader

    /// Attempted to process a nil or invalid payment intent
    case confirmInvalidPaymentIntent

    /// Attempted to connect from an unsupported version of the SDK.
    /// In order to fix this you will need to update your app
    /// to the most recent version of the SDK.
    case unsupportedSDK

    /// This feature is currently not available for the selected reader.
    /// e.g.: attempting to create a local payment intent on a reader that
    /// requires the payment intent to be created on the backend
    case featureNotAvailableWithConnectedReader

    /// A command was cancelled
    case commandCancelled(from: CancellationSource)

    /// A command can be cancelled on the reader, or in the app.
    /// Note that this is not produced by Stripe, we have to infer it from commandCancelled, so we start with `.unknown`.
    public enum CancellationSource {
        case unknown
        case app
        case reader
    }

    /// Access to location services is currently disabled. This may be because:
    /// - The user disabled location services in the system settings.
    /// - The user denied access to location services for your app.
    /// - The user’s device is in Airplane Mode and unable to gather location data.
    case locationServicesDisabled

    /// This error indicates that Bluetooth is turned off, and the user should use Settings to turn Bluetooth on.
    /// If Bluetooth is on but the app does not have permission to use it, a different error (bluetoothError) occurs.
    case bluetoothDisabled

    /// Generic bluetooth error. Among other things, it may indicate that the app does not have permission to use Bluetooth.
    case bluetoothError

    /// Scanning for bluetooth devices timed out.
    case bluetoothScanTimedOut

    /// Bluetooth Low Energy is unsupported on this iOS device. Use a different iOS device that supports BLE (also known as Bluetooth 4.0)
    case bluetoothLowEnergyUnsupported

    /// The reader has a critically low battery and cannot connect to the iOS device. Charge the reader before trying again.
    case bluetoothConnectionFailedBatteryCriticallyLow

    /// Updating the reader software failed because the reader’s battery is too low. Charge the reader before trying again.
    case readerSoftwareUpdateFailedBatteryLow

    /// Updating the reader software failed because the update was interrupted.
    case readerSoftwareUpdateFailedInterrupted

    /// Generic reader software update error.
    case readerSoftwareUpdateFailed

    /// Updating the reader software failed because there was an error communicating with the reader.
    case readerSoftwareUpdateFailedReader

    /// Updating the reader software failed because there was an error communicating with the update server.
    case readerSoftwareUpdateFailedServer

    /// The card is not a chip card.
    case cardInsertNotRead

    /// The swipe could not be read.
    case cardSwipeNotRead

    /// Reading a card timed out.
    case cardReadTimeOut

    /// The card was removed during the transaction.
    case cardRemoved

    /// A card can only be used for one transaction, and must be removed after being read
    case cardLeftInReader

    /// The reader is busy.
    case readerBusy

    /// An incompatible reader was detected.
    case readerIncompatible

    /// Could not communicate with the reader.
    case readerCommunicationError

    /// Connecting to the bluetooth device timed out.
    /// Make sure the device is powered on, in range, and not connected to another app or device.
    /// If this error continues to occur, you may need to charge the device.
    case bluetoothConnectTimedOut

    /// The Bluetooth device was disconnected unexpectedly.
    case bluetoothDisconnected

    /// The user has denied the app permission to use Bluetooth
    case bluetoothDenied

    /// An attempt to process a payment was made from a reader with an unsupported reader version.
    /// You will need to update your reader to the most recent version in order to accept payments
    case unsupportedReaderVersion

    /// Connecting to the reader failed because it is currently in use
    case connectFailedReaderIsInUse

    /// Call 911. Unexpected SDK error.
    case unexpectedSDKError

    /// The Stripe API declined the payment
    case paymentDeclinedByPaymentProcessorAPI(declineReason: DeclineReason)

    /// The reader declined the payment. Try another card.
    case paymentDeclinedByCardReader

    /// The SDK is not connected to the internet.
    case notConnectedToInternet

    /// The underlying request timed out.
    case requestTimedOut

    /// The current session has expired and the reader must be disconnected and reconnected.
    /// The SDK will attempt to auto-disconnect for you and you should instruct your user to reconnect it.
    case readerSessionExpired

    /// The underlying request returned an API error.
    case processorAPIError

    /// Catch-all error case. Indicates there is something wrong with the
    /// internal state of the CardReaderService.
    case internalServiceError

    /// The store setup is incomplete, and the action can't be performed until the user provides a full store address in the site admin.
    /// May include the URL for the appropriate admin page
    case incompleteStoreAddress(adminUrl: URL?)

    /// The store setup is incomplete, and the action can't be performed until the user provides a valid postal code in the site admin.
    case invalidPostalCode

    /// There was no refund in progress to cancel
    case noRefundInProgress

    /// Connection attempt invalidated while it was in progress – e.g. the store was changed during a connection
    case connectionAttemptInvalidated

    /// Errors that originate because there's no active payment intent, so the operation is invalid, e.g. cancelling the active PI when there isn't one.
    ///
    case noActivePaymentIntent

    // MARK: - Tap to Pay on iPhone related errors

    /// The device must have a passcode in order to use Tap to Pay on iPhone
    /// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html#/c:@E@SCPError@SCPErrorPasscodeNotEnabled
    case passcodeNotEnabled

    /// The phone must have a signed-in iCloud account in order to accept the TOS for the built in reader.
    /// The signed-in account does not need to be the one used to connect the reader.
    /// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html#/c:@E@SCPError@SCPErrorAppleBuiltInReaderTOSAcceptanceRequiresiCloudSignIn
    case appleBuiltInReaderTOSAcceptanceRequiresiCloudSignIn

    /// NFC is disabled on the device. This could be a permissions issue, in particular due to a device management profile.
    /// It's unlikely that the user can directly correct this issue
    /// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html#/c:@E@SCPError@SCPErrorNFCDisabled
    case nfcDisabled

    /// Preparing Tap to Pay on iPhone failed. This is a retriable error
    /// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html#/c:@E@SCPError@SCPErrorAppleBuiltInReaderFailedToPrepare
    case appleBuiltInReaderFailedToPrepare

    /// The user cancelled Tap to Pay on iPhone Terms of Service acceptance
    /// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html#/c:@E@SCPError@SCPErrorAppleBuiltInReaderTOSAcceptanceCanceled
    case appleBuiltInReaderTOSAcceptanceCanceled

    /// Tap to Pay on iPhone Terms of Service have not been accepted. This error is retriable
    /// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html#/c:@E@SCPError@SCPErrorAppleBuiltInReaderTOSNotYetAccepted
    case appleBuiltInReaderTOSNotYetAccepted

    /// Tap to Pay on iPhone Terms of Service could not be accepted. This may indicate an issue with the Apple ID used.
    /// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html#/c:@E@SCPError@SCPErrorAppleBuiltInReaderTOSAcceptanceFailed
    case appleBuiltInReaderTOSAcceptanceFailed

    /// This (Stripe) merchant account cannot be used with Tap to Pay on iPhone as it has been blocked
    /// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html#/c:@E@SCPError@SCPErrorAppleBuiltInReaderMerchantBlocked
    case appleBuiltInReaderMerchantBlocked

    /// The merchant account is invalid and cannot be used with Tap to Pay on iPhone
    /// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html#/c:@E@SCPError@SCPErrorAppleBuiltInReaderInvalidMerchant
    case appleBuiltInReaderInvalidMerchant

    /// Tap to Pay on iPhone on this device cannot be used because it has been banned
    /// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html#/c:@E@SCPError@SCPErrorAppleBuiltInReaderDeviceBanned
    case appleBuiltInReaderDeviceBanned

    /// The device does not meet the minimum requirements for using Tap to Pay on iPhone
    /// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html#/c:@E@SCPError@SCPErrorUnsupportedMobileDeviceConfiguration
    case unsupportedMobileDeviceConfiguration

    /// Tap to Pay on iPhone cannot be used while the app is in the background
    /// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html#/c:@E@SCPError@SCPErrorReaderNotAccessibleInBackground
    case readerNotAccessibleInBackground

    /// Tap to Pay on iPhone cannot be used during a phone call
    /// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html#/c:@E@SCPError@SCPErrorCommandNotAllowedDuringCall
    case commandNotAllowedDuringCall

    /// The amount charged was not supported by the reader.
    /// (This may be a different amount than the minimum for a payment with Stripe. There is a maximum too.)
    /// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html#/c:@E@SCPError@SCPErrorInvalidAmount
    case invalidAmount

    /// The currency used was not supported by the reader.
    /// The reader may support a different set of currencies than WCPay or Stripe.
    /// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html#/c:@E@SCPError@SCPErrorInvalidCurrency
    case invalidCurrency

    /// The operation could not be canceled because it was already completed.
    /// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html#/c:@E@SCPError@SCPErrorCancelFailedAlreadyCompleted
    case cancelFailedAlreadyCompleted

    /// The payment intent is missing.
    /// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html#/c:@E@SCPError@SCPErrorNilPaymentIntent
    case nilPaymentIntent

    /// The setup intent is missing.
    /// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html#/c:@E@SCPError@SCPErrorNilSetupIntent
    case nilSetupIntent

    /// The refund payment method is missing.
    /// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html#/c:@E@SCPError@SCPErrorNilRefundPaymentMethod
    case nilRefundPaymentMethod

    /// The refund parameters are invalid.
    /// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html#/c:@E@SCPError@SCPErrorInvalidRefundParameters
    case invalidRefundParameters

    /// The client secret is invalid.
    /// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html#/c:@E@SCPError@SCPErrorInvalidClientSecret
    case invalidClientSecret

    /// The discovery configuration is invalid.
    /// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html#/c:@E@SCPError@SCPErrorInvalidDiscoveryConfiguration
    case invalidDiscoveryConfiguration

    /// The reader for update is invalid.
    /// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html#/c:@E@SCPError@SCPErrorInvalidReaderForUpdate
    case invalidReaderForUpdate

    /// The feature is unavailable.
    /// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html#/c:@E@SCPError@SCPErrorFeatureNotAvailable
    case featureNotAvailable

    /// The Bluetooth connection has an invalid location ID parameter.
    /// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html#/c:@E@SCPError@SCPErrorBluetoothConnectionInvalidLocationIdParameter
    case bluetoothConnectionInvalidLocationIdParameter

    /// A required parameter is invalid.
    /// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html#/c:@E@SCPError@SCPErrorInvalidRequiredParameter
    case invalidRequiredParameter

    /// Forwarding a test mode payment in live mode is prohibited.
    /// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html#/c:@E@SCPError@SCPErrorForwardingTestModePaymentInLiveMode
    case forwardingTestModePaymentInLiveMode

    /// Forwarding a live mode payment in test mode is prohibited.
    /// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html#/c:@E@SCPError@SCPErrorForwardingLiveModePaymentInTestMode
    case forwardingLiveModePaymentInTestMode

    /// The reader connection configuration is invalid.
    /// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html#/c:@E@SCPError@SCPErrorReaderConnectionConfigurationInvalid
    case readerConnectionConfigurationInvalid

    /// The reader tipping parameter is invalid.
    /// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html#/c:@E@SCPError@SCPErrorReaderTippingParameterInvalid
    case readerTippingParameterInvalid

    /// The location ID parameter is invalid.
    /// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html#/c:@E@SCPError@SCPErrorInvalidLocationIdParameter
    case invalidLocationIdParameter

    /// The reader software update failed due to an expired update.
    /// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html#/c:@E@SCPError@SCPErrorReaderSoftwareUpdateFailedExpiredUpdate
    case readerSoftwareUpdateFailedExpiredUpdate

    /// The reader connection is unavailable offline.
    /// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html#/c:@E@SCPError@SCPErrorReaderConnectionNotAvailableOffline
    case readerConnectionNotAvailableOffline

    /// There is a location mismatch in the offline reader connection.
    /// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html#/c:@E@SCPError@SCPErrorReaderConnectionOfflineLocationMismatch
    case readerConnectionOfflineLocationMismatch

    /// The offline reader connection needs an update.
    /// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html#/c:@E@SCPError@SCPErrorReaderConnectionOfflineNeedsUpdate
    case readerConnectionOfflineNeedsUpdate

    /// The amount exceeds the maximum allowed for offline transactions.
    /// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html#/c:@E@SCPError@SCPErrorAmountExceedsMaxOfflineAmount
    case amountExceedsMaxOfflineAmount

    /// The offline currency is invalid.
    /// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html#/c:@E@SCPError@SCPErrorInvalidOfflineCurrency
    case invalidOfflineCurrency

    /// EMV data is missing.
    /// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html#/c:@E@SCPError@SCPErrorMissingEMVData
    case missingEMVData

    /// The command is not allowed.
    /// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html#/c:@E@SCPError@SCPErrorCommandNotAllowed
    case commandNotAllowed

    /// Collect inputs operation timed out.
    /// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html#/c:@E@SCPError@SCPErrorCollectInputsTimedOut
    case collectInputsTimedOut

    /// USB discovery operation timed out.
    /// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html#/c:@E@SCPError@SCPErrorUsbDiscoveryTimedOut
    case usbDiscoveryTimedOut

    /// The Bluetooth peer removed pairing information.
    /// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html#/c:@E@SCPError@SCPErrorBluetoothPeerRemovedPairingInformation
    case bluetoothPeerRemovedPairingInformation

    /// Bluetooth is already paired with another device.
    /// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html#/c:@E@SCPError@SCPErrorBluetoothAlreadyPairedWithAnotherDevice
    case bluetoothAlreadyPairedWithAnotherDevice

    /// The reader's IP address is unknown.
    /// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html#/c:@E@SCPError@SCPErrorUnknownReaderIpAddress
    case unknownReaderIpAddress

    /// Internet connection operation timed out.
    /// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html#/c:@E@SCPError@SCPErrorInternetConnectTimeOut
    case internetConnectTimeOut

    /// Bluetooth reconnect has started.
    /// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html#/c:@E@SCPError@SCPErrorBluetoothReconnectStarted
    case bluetoothReconnectStarted

    /// The Apple built-in reader account is deactivated.
    /// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html#/c:@E@SCPError@SCPErrorAppleBuiltInReaderAccountDeactivated
    case appleBuiltInReaderAccountDeactivated

    /// The reader is missing encryption keys.
    /// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html#/c:@E@SCPError@SCPErrorReaderMissingEncryptionKeys
    case readerMissingEncryptionKeys

    /// USB connection was disconnected.
    /// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html#/c:@E@SCPError@SCPErrorUsbDisconnected
    case usbDisconnected

    /// An unexpected error occurred with the reader.
    /// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html#/c:@E@SCPError@SCPErrorUnexpectedReaderError
    case unexpectedReaderError

    /// There is a failure with the encryption key.
    /// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html#/c:@E@SCPError@SCPErrorEncryptionKeyFailure
    case encryptionKeyFailure

    /// The encryption key is still initializing.
    /// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html#/c:@E@SCPError@SCPErrorEncryptionKeyStillInitializing
    case encryptionKeyStillInitializing

    /// There is an application error with collect inputs.
    /// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html#/c:@E@SCPError@SCPErrorCollectInputsApplicationError
    case collectInputsApplicationError

    /// The command requires cardholder consent.
    /// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html#/c:@E@SCPError@SCPErrorCommandRequiresCardholderConsent
    case commandRequiresCardholderConsent

    /// The refund operation failed.
    /// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html#/c:@E@SCPError@SCPErrorRefundFailed
    case refundFailed

    /// Card swipe functionality is unavailable.
    /// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html#/c:@E@SCPError@SCPErrorCardSwipeNotAvailable
    case cardSwipeNotAvailable

    /// Interac is not supported in offline mode.
    /// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html#/c:@E@SCPError@SCPErrorInteracNotSupportedOffline
    case interacNotSupportedOffline

    /// The card is expired and offline mode is active.
    /// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html#/c:@E@SCPError@SCPErrorOfflineAndCardExpired
    case offlineAndCardExpired

    /// The offline transaction was declined.
    /// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html#/c:@E@SCPError@SCPErrorOfflineTransactionDeclined
    case offlineTransactionDeclined

    /// There is a mismatch between offline collect and confirm.
    /// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html#/c:@E@SCPError@SCPErrorOfflineCollectAndConfirmMismatch
    case offlineCollectAndConfirmMismatch

    /// Online PIN is not supported in offline mode.
    /// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html#/c:@E@SCPError@SCPErrorOnlinePinNotSupportedOffline
    case onlinePinNotSupportedOffline

    /// A test card is used in live mode while offline.
    /// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html#/c:@E@SCPError@SCPErrorOfflineTestCardInLivemode
    case offlineTestCardInLivemode

    /// There is an error decoding the Stripe API response.
    /// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html#/c:@E@SCPError@SCPErrorStripeAPIResponseDecodingError
    case stripeAPIResponseDecodingError

    /// An internal network error occurred.
    /// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html#/c:@E@SCPError@SCPErrorInternalNetworkError
    case internalNetworkError

    /// The connection token provider finished with an error.
    /// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html#/c:@E@SCPError@SCPErrorConnectionTokenProviderCompletedWithError
    case connectionTokenProviderCompletedWithError

    /// The connection token provider operation timed out.
    /// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html#/c:@E@SCPError@SCPErrorConnectionTokenProviderTimedOut
    case connectionTokenProviderTimedOut

    /// Not connected to the internet, but online behavior is required.
    /// https://stripe.dev/stripe-terminal-ios/docs/Enums/SCPError.html#/c:@E@SCPError@SCPErrorNotConnectedToInternetAndOfflineBehaviorRequireOnline
    case notConnectedToInternetAndOfflineBehaviorRequireOnline
}

extension UnderlyingError {
    /// Determine an UnderlyingError for an Error related to the Card Reader, e.g. CardReaderConfigError, errors from StripeTerminal in SCPError.
    /// This will return `internalServiceError` as a catch-all if no more specific error can be determined.
    init(with error: Error) {
        switch error {
        case let configurationError as CardReaderConfigError:
            if let underlyingConfigurationError = UnderlyingError(withConfigError: (configurationError)) {
                self = underlyingConfigurationError
                return
            }
        default:
            #if !targetEnvironment(macCatalyst)
            if let underlyingStripeError = UnderlyingError(withStripeError: error) {
                self = underlyingStripeError
                return
            }
            #else
            break
            #endif
        }
        self = .internalServiceError
    }

    init?(withConfigError configError: CardReaderConfigError) {
        switch configError {
        case .incompleteStoreAddress(let adminUrl):
            self = .incompleteStoreAddress(adminUrl: adminUrl)
        case .invalidPostalCode:
            self = .invalidPostalCode
        }
    }
}

extension UnderlyingError {
    /// Returns true if the error is related to card reader software updates
    ///
    public var isSoftwareUpdateError: Bool {
        switch self {
        case .readerSoftwareUpdateFailed,
             .readerSoftwareUpdateFailedReader,
             .readerSoftwareUpdateFailedServer,
             .readerSoftwareUpdateFailedInterrupted,
             .readerSoftwareUpdateFailedBatteryLow:
            return true
        default:
            return false
        }
    }
}

extension UnderlyingError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .notConnectedToReader:
            return NSLocalizedString("No card reader is connected - connect a reader and try again.",
                                     comment: "Error message when a card reader was expected to already have been connected.")

        case .alreadyConnectedToReader:
            return NSLocalizedString("Unable to connect to reader - another reader is already connected.",
                                     comment: "Error message when a card reader is already connected and we were not expecting one.")

        case .confirmInvalidPaymentIntent:
            return NSLocalizedString("Unable to process payment due to invalid data - please try again.",
                                     comment: "Error message when the payment intent is invalid.")

        case .unsupportedSDK:
            return NSLocalizedString("Unable to perform software request - please update this application and try again.",
                                     comment: "Error message when the application is so out of date that the backend refuses to work with it.")

        case .featureNotAvailableWithConnectedReader:
            return NSLocalizedString("Unable to perform request with the connected reader - unsupported feature - please try again with another reader.",
                                     comment: "Error message when the card reader cannot be used to perform the requested task.")

        case .commandCancelled(let cancellationSource):
            switch cancellationSource {
            case .reader:
                return NSLocalizedString("The payment was canceled on the reader.",
                                         comment: "Error message when the cancel button on the reader is used.")
            default:
                return NSLocalizedString("The system canceled the command unexpectedly - please try again.",
                                         comment: "Error message when the system cancels a command.")
            }

        case .locationServicesDisabled:
            return NSLocalizedString("Unable to access Location Services - please enable Location Services and try again.",
                                     comment: "Error message when location services is not enabled for this application.")

        case .bluetoothDisabled:
            return NSLocalizedString("Unable to access Bluetooth - please enable Bluetooth and try again.",
                                     comment: "Error message when Bluetooth is not enabled or available.")

        case .bluetoothError:
            return NSLocalizedString("An error occurred accessing Bluetooth - please enable Bluetooth and try again.",
                                     comment: "Error message when Bluetooth is not enabled for this application.")

        case .bluetoothScanTimedOut:
            return NSLocalizedString("Unable to search for card readers - Bluetooth timed out - please try again.",
                                     comment: "Error message when Bluetooth scan times out during reader discovery.")

        case .bluetoothLowEnergyUnsupported:
            return NSLocalizedString("Unable to search for card readers - Bluetooth Low Energy is not supported on this device - please use a different device.",
                                     comment: "Error message when Bluetooth Low Energy is not supported on the user device.")

        case .bluetoothConnectionFailedBatteryCriticallyLow:
            return NSLocalizedString("Unable to connect to reader - the reader has a critically low battery - charge the reader and try again.",
                                     comment: "Error message the card reader battery level is too low to connect to the phone or tablet.")

        case .bluetoothDenied:
            return NSLocalizedString(
                "hardware.cardReader.underlyingError.bluetoothDenied",
                value: "This app needs permission to access Bluetooth to connect to your card reader. " +
                       "You can grant permission in the system's Settings app, in the Woo section.",
                comment: "Explanation in the alert presented when the user tries to connect a Bluetooth card reader with insufficient permissions"
            )

        case .readerSoftwareUpdateFailedBatteryLow:
            return NSLocalizedString("Unable to update card reader software - the reader battery is too low.",
                                     comment: "Error message when the card reader battery level is too low to safely perform a software update.")

        case .readerSoftwareUpdateFailedInterrupted:
            return NSLocalizedString("The card reader software update was interrupted before it could complete - please try again.",
                                     comment: "Error message when the card reader software update is interrupted.")

        case .readerSoftwareUpdateFailed:
            return NSLocalizedString("The card reader software update failed unexpectedly - please try again.",
                                     comment: "Error message when the card reader software update fails unexpectedly.")

        case .readerSoftwareUpdateFailedReader:
            return NSLocalizedString("The card reader software update failed due to a communication error - please try again.",
                                     comment: "Error message when the card reader software update fails due to a communication error.")

        case .readerSoftwareUpdateFailedServer:
            return NSLocalizedString("The card reader software update failed due to a problem with the update server - please try again.",
                                     comment: "Error message when the card reader software update fails due to a problem with the update server.")

        case .cardInsertNotRead:
            return NSLocalizedString("Unable to read inserted card - please try removing and inserting card again.",
                                     comment: "Error message when the card reader is unable to read any chip on the inserted card.")

        case .cardSwipeNotRead:
            return NSLocalizedString("Unable to read swiped card - please try swiping again.",
                                     comment: "Error message when the card reader is unable to read a swiped card.")

        case .cardReadTimeOut:
            return NSLocalizedString("Unable to read card - the system timed out - please try again.",
                                     comment: "Error message when the card reader times out while reading a card.")

        case .cardRemoved:
            return NSLocalizedString("Card was removed too soon - please try transaction again.",
                                     comment: "Error message when the card is removed from the reader prematurely.")

        case .cardLeftInReader:
            return NSLocalizedString("Card was left in reader - please remove and reinsert card.",
                                     comment: "Error message when a card is left in the reader and another transaction started.")

        case .readerBusy:
            return NSLocalizedString("The card reader is busy executing another command - please try again.",
                                     comment: "Error message when the card reader is busy executing another command.")

        case .readerIncompatible:
            return NSLocalizedString("The card reader is not compatible with this application - please try updating the " +
                                     "application or using a different reader.",
                                     comment: "Error message when the card reader is incompatible with the application.")

        case .readerCommunicationError:
            return NSLocalizedString("Unable to communicate with reader - please try again.",
                                     comment: "Error message when communication with the card reader is disrupted.")

        case .bluetoothConnectTimedOut:
            return NSLocalizedString("Connecting to the card reader timed out - ensure it is nearby and charged and then try again.",
                                     comment: "Error message when establishing a connection to the card reader times out.")

        case .bluetoothDisconnected:
            return NSLocalizedString("The Bluetooth connection to the card reader disconnected unexpectedly.",
                                     comment: "Error message when the card reader loses its Bluetooth connection to the card reader.")

        case .unsupportedReaderVersion:
            return NSLocalizedString("The card reader software is out-of-date - please update the card reader software before attempting to process payments.",
                                     comment: "Error message when the card reader software is too far out of date to process payments.")

        case .connectFailedReaderIsInUse:
            return NSLocalizedString("Unable to connect to card reader - the card reader is already in use.",
                                     comment: "Error message when attempting to connect to a card reader which is already in use.")

        case .unexpectedSDKError:
            return NSLocalizedString("The system experienced an unexpected software error.",
                                     comment: "Error message when the card reader service experiences an unexpected software error.")

        case .paymentDeclinedByPaymentProcessorAPI:
            if case let .paymentDeclinedByPaymentProcessorAPI(declineReason) = self {
                return declineReason.localizedDescription
            }
            return NSLocalizedString("The card was declined by the payment processor - please try another means of payment.",
                                     comment: "Error message when the card processor declines the payment.")

        case .paymentDeclinedByCardReader:
            return NSLocalizedString("The card was declined by the card reader - please try another means of payment.",
                                     comment: "Error message when the card reader itself declines the card.")

        case .notConnectedToInternet:
            return NSLocalizedString("No connection to the Internet - please connect to the Internet and try again.",
                                     comment: "Error message when there is no connection to the Internet.")

        case .requestTimedOut:
            return NSLocalizedString("The request timed out - please try again.",
                                     comment: "Error message when a request times out.")

        case .readerSessionExpired:
            return NSLocalizedString("The card reader session has expired - please disconnect and reconnect the card reader and then try again.",
                                     comment: "Error message when the card reader session has timed out.")

        case .processorAPIError:
            return NSLocalizedString("The payment can not be processed by the payment processor.",
                                     comment: "Error message when the payment can not be processed (i.e. order amount is below the minimum amount allowed.)")

        case .internalServiceError:
            return NSLocalizedString("Sorry, this payment couldn’t be processed.",
                                     comment: "Error message when the card reader service experiences an unexpected internal service error.")

        case .incompleteStoreAddress:
            return NSLocalizedString("The store address is incomplete or missing, please update it before continuing.",
                                     comment: "Error message when there is an issue with the store address preventing " +
                                     "an action (e.g. reader connection.)")

        case .invalidPostalCode:
            return NSLocalizedString("The store postal code is invalid or missing, please update it before continuing.",
                                     comment: "Error message when there is an issue with the store postal code preventing " +
                                     "an action (e.g. reader connection.)")

        case .noRefundInProgress:
            return NSLocalizedString("Sorry, this refund could not be canceled.",
                                     comment: "Error message shown when a refund could not be canceled (likely because " +
                                     "it had already completed)")

        case .connectionAttemptInvalidated:
            return NSLocalizedString("Sorry, we could not connect to the reader. Please try again.",
                                     comment: "Error message shown when an in-progress connection is cancelled by the system")

        case .noActivePaymentIntent:
            return NSLocalizedString("Sorry, we could not complete this action, as no active payment was found.",
                                     comment: "Underlying error message for actions which require an active payment, " +
                                     "such as cancellation, when none is found. Unlikely to be shown.")

            // MARK: - Tap to Pay on iPhone errors
        case .passcodeNotEnabled:
            return NSLocalizedString("You need to set a lock screen passcode to use Tap to Pay on iPhone.",
                                     comment: "Error message shown when Tap to Pay on iPhone cannot be used because " +
                                     "the device does not have a passcode set.")

        case .appleBuiltInReaderTOSAcceptanceRequiresiCloudSignIn:
            return NSLocalizedString("Please sign in to iCloud on this device to use Tap to Pay on iPhone.",
                                     comment: "Error message shown when Tap to Pay on iPhone cannot be used because " +
                                     "the device is not signed in to iCloud.")

        case .nfcDisabled:
            return NSLocalizedString("The app could not enable Tap to Pay on iPhone, because the NFC chip is disabled. " +
                                     "Please contact support for more details.",
                                     comment: "Error message shown when Tap to Pay on iPhone cannot be used because " +
                                     "the device's NFC chipset has been disabled by a device management policy.")

        case .appleBuiltInReaderFailedToPrepare, .readerNotAccessibleInBackground:
            return NSLocalizedString("There was an issue preparing to use Tap to Pay on iPhone – please try again.",
                                     comment: "Error message shown when Tap to Pay on iPhone cannot be used because " +
                                     "there was some issue with the connection. Retryable.")

        case .appleBuiltInReaderTOSAcceptanceCanceled, .appleBuiltInReaderTOSNotYetAccepted:
            return NSLocalizedString("Please try again, and accept Apple's Terms of Service, so you can use Tap to " +
                                     "Pay on iPhone.",
                                     comment: "Error message shown when Tap to Pay on iPhone cannot be used because " +
                                     "the merchant cancelled or did not complete the Terms of Service acceptance flow")

        case .appleBuiltInReaderTOSAcceptanceFailed:
            return NSLocalizedString("Please check your Apple ID is valid, and then try again. A valid Apple ID is " +
                                     "required to accept Apple's Terms of Service.",
                                     comment: "Error message shown when Tap to Pay on iPhone cannot be used because " +
                                     "the Terms of Service acceptance flow failed, possibly due to issues with " +
                                     "the Apple ID")

        case .appleBuiltInReaderMerchantBlocked, .appleBuiltInReaderInvalidMerchant, .appleBuiltInReaderDeviceBanned:
            return NSLocalizedString("Please contact support – there was an issue starting Tap to Pay on iPhone",
                                     comment: "Error message shown when Tap to Pay on iPhone cannot be used because " +
                                     "there is an issue with the merchant account or device.")

        case .unsupportedMobileDeviceConfiguration:
            /// Sometimes there are different requirements in different countries but it's overly complicated to make this country specific.
            /// Use the highest version number required by a country in this message.
            return NSLocalizedString("Please check that your phone meets these requirements: " +
                                     "iPhone XS or newer running iOS 16.7 or above. Contact support if this error " +
                                     "shows on a supported device.",
                                     comment: "Error message shown when Tap to Pay on iPhone cannot be used because " +
                                     "the device does not meet minimum requirements.")

        case .commandNotAllowedDuringCall:
            return NSLocalizedString("Tap to Pay on iPhone cannot be used during a phone call. Please try again after " +
                                     "you finish your call.",
                                     comment: "Error message shown when Tap to Pay on iPhone cannot be used because " +
                                     "there is a call in progress")

        case .invalidAmount:
            return NSLocalizedString("The amount is not supported for Tap to Pay on iPhone – please try a hardware " +
                                     "reader or another payment method.",
                                     comment: "Error message shown when Tap to Pay on iPhone cannot be used because " +
                                     "the amount for payment is not supported for Tap to Pay on iPhone.")

        case .invalidCurrency:
            return NSLocalizedString("The currency is not supported for Tap to Pay on iPhone – please try a hardware " +
                                     "reader or another payment method.",
                                     comment: "Error message shown when Tap to Pay on iPhone cannot be used because " +
                                     "the currency for payment is not supported for Tap to Pay on iPhone.")

        case .cancelFailedAlreadyCompleted:
            return NSLocalizedString(
                "hardware.cardReader.underlyingError.cancelFailedAlreadyCompleted",
                value: "The operation could not be canceled because it was already completed.",
                comment: "Error message when an operation cannot be canceled because it is already completed."
            )

        case .nilPaymentIntent:
            return NSLocalizedString(
                "hardware.cardReader.underlyingError.nilPaymentIntent",
                value: "The payment intent is missing.",
                comment: "Error message when the payment intent is missing."
            )

        case .nilSetupIntent:
            return NSLocalizedString(
                "hardware.cardReader.underlyingError.nilSetupIntent",
                value: "The setup intent is missing.",
                comment: "Error message when the setup intent is missing."
            )

        case .nilRefundPaymentMethod:
            return NSLocalizedString(
                "hardware.cardReader.underlyingError.nilRefundPaymentMethod",
                value: "The refund payment method is missing.",
                comment: "Error message when the refund payment method is missing."
            )

        case .invalidRefundParameters:
            return NSLocalizedString(
                "hardware.cardReader.underlyingError.invalidRefundParameters",
                value: "The refund parameters are invalid.",
                comment: "Error message when the refund parameters are invalid."
            )

        case .invalidClientSecret:
            return NSLocalizedString(
                "hardware.cardReader.underlyingError.invalidClientSecret",
                value: "The client secret is invalid.",
                comment: "Error message when the client secret is invalid."
            )

        case .invalidDiscoveryConfiguration:
            return NSLocalizedString(
                "hardware.cardReader.underlyingError.invalidDiscoveryConfiguration",
                value: "The discovery configuration is invalid.",
                comment: "Error message when the discovery configuration is invalid."
            )

        case .invalidReaderForUpdate:
            return NSLocalizedString(
                "hardware.cardReader.underlyingError.invalidReaderForUpdate",
                value: "The reader for update is invalid.",
                comment: "Error message when the reader for update is invalid."
            )

        case .featureNotAvailable:
            return NSLocalizedString(
                "hardware.cardReader.underlyingError.featureNotAvailable",
                value: "The feature is unavailable.",
                comment: "Error message when a feature is unavailable."
            )

        case .bluetoothConnectionInvalidLocationIdParameter:
            return NSLocalizedString(
                "hardware.cardReader.underlyingError.bluetoothConnectionInvalidLocationIdParameter",
                value: "The Bluetooth connection has an invalid location ID.",
                comment: "Error message when the Bluetooth connection has an invalid location ID parameter."
            )

        case .invalidRequiredParameter:
            return NSLocalizedString(
                "hardware.cardReader.underlyingError.invalidRequiredParameter",
                value: "A required parameter is invalid.",
                comment: "Error message when a required parameter is invalid."
            )

        case .forwardingTestModePaymentInLiveMode:
            return NSLocalizedString(
                "hardware.cardReader.underlyingError.forwardingTestModePaymentInLiveMode",
                value: "Forwarding a test mode payment in live mode is prohibited.",
                comment: "Error message when forwarding a test mode payment in live mode is prohibited."
            )

        case .forwardingLiveModePaymentInTestMode:
            return NSLocalizedString(
                "hardware.cardReader.underlyingError.forwardingLiveModePaymentInTestMode",
                value: "Forwarding a live mode payment in test mode is prohibited.",
                comment: "Error message when forwarding a live mode payment in test mode is prohibited."
            )

        case .readerConnectionConfigurationInvalid:
            return NSLocalizedString(
                "hardware.cardReader.underlyingError.readerConnectionConfigurationInvalid",
                value: "The reader connection configuration is invalid.",
                comment: "Error message when the reader connection configuration is invalid."
            )

        case .readerTippingParameterInvalid:
            return NSLocalizedString(
                "hardware.cardReader.underlyingError.readerTippingParameterInvalid",
                value: "The reader tipping parameter is invalid.",
                comment: "Error message when the reader tipping parameter is invalid."
            )

        case .invalidLocationIdParameter:
            return NSLocalizedString(
                "hardware.cardReader.underlyingError.invalidLocationIdParameter",
                value: "The location ID is invalid.",
                comment: "Error message when the location ID parameter is invalid."
            )

        case .readerSoftwareUpdateFailedExpiredUpdate:
            return NSLocalizedString(
                "hardware.cardReader.underlyingError.readerSoftwareUpdateFailedExpiredUpdate",
                value: "The reader software update failed due to an expired update.",
                comment: "Error message when the reader software update fails due to an expired update."
            )

        case .readerConnectionNotAvailableOffline:
            return NSLocalizedString(
                "hardware.cardReader.underlyingError.readerConnectionNotAvailableOffline",
                value: "The reader connection is unavailable offline.",
                comment: "Error message when the reader connection is unavailable offline."
            )

        case .readerConnectionOfflineLocationMismatch:
            return NSLocalizedString(
                "hardware.cardReader.underlyingError.readerConnectionOfflineLocationMismatch",
                value: "Reader connection failed because the reader was most recently connected to a different location while online.",
                comment: "Error message when there is a location mismatch in the reader connection."
            )

        case .readerConnectionOfflineNeedsUpdate:
            return NSLocalizedString(
                "hardware.cardReader.underlyingError.readerConnectionOfflineNeedsUpdate",
                value: "The offline reader connection needs an update.",
                comment: "Error message when the offline reader connection needs an update."
            )

        case .amountExceedsMaxOfflineAmount:
            return NSLocalizedString(
                "hardware.cardReader.underlyingError.amountExceedsMaxOfflineAmount",
                value: "The amount exceeds the maximum allowed for offline transactions.",
                comment: "Error message when the amount exceeds the maximum allowed for offline transactions."
            )

        case .invalidOfflineCurrency:
            return NSLocalizedString(
                "hardware.cardReader.underlyingError.invalidOfflineCurrency",
                value: "The offline currency is invalid.",
                comment: "Error message when the offline currency is invalid."
            )

        case .missingEMVData:
            return NSLocalizedString(
                "hardware.cardReader.underlyingError.missingEMVData",
                value: "EMV data is missing.",
                comment: "Error message when EMV data is missing."
            )

        case .commandNotAllowed:
            return NSLocalizedString(
                "hardware.cardReader.underlyingError.commandNotAllowed",
                value: "The command is not allowed.",
                comment: "Error message when the command is not allowed."
            )

        case .collectInputsTimedOut:
            return NSLocalizedString(
                "hardware.cardReader.underlyingError.collectInputsTimedOut",
                value: "Collect inputs operation timed out.",
                comment: "Error message when the collect inputs operation timed out."
            )

        case .usbDiscoveryTimedOut:
            return NSLocalizedString(
                "hardware.cardReader.underlyingError.usbDiscoveryTimedOut",
                value: "USB discovery operation timed out.",
                comment: "Error message when the USB discovery operation timed out."
            )

        case .bluetoothPeerRemovedPairingInformation:
            return NSLocalizedString(
                "hardware.cardReader.underlyingError.bluetoothPeerRemovedPairingInformation",
                value: "The Bluetooth peer removed pairing information.",
                comment: "Error message when the Bluetooth peer removed pairing information."
            )

        case .bluetoothAlreadyPairedWithAnotherDevice:
            return NSLocalizedString(
                "hardware.cardReader.underlyingError.bluetoothAlreadyPairedWithAnotherDevice",
                value: "Bluetooth is already paired with another device.",
                comment: "Error message when Bluetooth is already paired with another device."
            )

        case .unknownReaderIpAddress:
            return NSLocalizedString(
                "hardware.cardReader.underlyingError.unknownReaderIpAddress",
                value: "The reader's IP address is unknown.",
                comment: "Error message when the reader's IP address is unknown."
            )

        case .internetConnectTimeOut:
            return NSLocalizedString(
                "hardware.cardReader.underlyingError.internetConnectTimeOut",
                value: "Internet connection operation timed out.",
                comment: "Error message when the internet connection operation timed out."
            )

        case .bluetoothReconnectStarted:
            return NSLocalizedString(
                "hardware.cardReader.underlyingError.bluetoothReconnectStarted",
                value: "Bluetooth reconnect has started.",
                comment: "Error message when Bluetooth reconnect has started."
            )

        case .appleBuiltInReaderAccountDeactivated:
            return NSLocalizedString(
                "hardware.cardReader.underlyingError.appleBuiltInReaderAccountDeactivated",
                value: "The Apple built-in reader account is deactivated.",
                comment: "Error message when the Apple built-in reader account is deactivated."
            )

        case .readerMissingEncryptionKeys:
            return NSLocalizedString(
                "hardware.cardReader.underlyingError.readerMissingEncryptionKeys",
                value: "The reader is missing encryption keys.",
                comment: "Error message when the reader is missing encryption keys."
            )

        case .usbDisconnected:
            return NSLocalizedString(
                "hardware.cardReader.underlyingError.usbDisconnected",
                value: "USB connection was disconnected.",
                comment: "Error message when the USB connection was disconnected."
            )

        case .unexpectedReaderError:
            return NSLocalizedString(
                "hardware.cardReader.underlyingError.unexpectedReaderError",
                value: "An unexpected error occurred with the reader.",
                comment: "Error message when an unexpected error occurs with the reader."
            )

        case .encryptionKeyFailure:
            return NSLocalizedString(
                "hardware.cardReader.underlyingError.encryptionKeyFailure",
                value: "There is a failure with the encryption key.",
                comment: "Error message when there is a failure with the encryption key."
            )

        case .encryptionKeyStillInitializing:
            return NSLocalizedString(
                "hardware.cardReader.underlyingError.encryptionKeyStillInitializing",
                value: "The encryption key is still initializing.",
                comment: "Error message when the encryption key is still initializing."
            )

        case .collectInputsApplicationError:
            return NSLocalizedString(
                "hardware.cardReader.underlyingError.collectInputsApplicationError",
                value: "There is an application error with collect inputs.",
                comment: "Error message when there is an application error with collect inputs."
            )

        case .commandRequiresCardholderConsent:
            return NSLocalizedString(
                "hardware.cardReader.underlyingError.commandRequiresCardholderConsent",
                value: "The command requires cardholder consent.",
                comment: "Error message when the command requires cardholder consent."
            )

        case .refundFailed:
            return NSLocalizedString(
                "hardware.cardReader.underlyingError.refundFailed",
                value: "The refund operation failed.",
                comment: "Error message when the refund operation failed."
            )

        case .cardSwipeNotAvailable:
            return NSLocalizedString(
                "hardware.cardReader.underlyingError.cardSwipeNotAvailable",
                value: "Card swipe functionality is unavailable.",
                comment: "Error message when card swipe functionality is unavailable."
            )

        case .interacNotSupportedOffline:
            return NSLocalizedString(
                "hardware.cardReader.underlyingError.interacNotSupportedOffline",
                value: "Interac is not supported in offline mode.",
                comment: "Error message when Interac is not supported in offline mode."
            )

        case .offlineAndCardExpired:
            return NSLocalizedString(
                "hardware.cardReader.underlyingError.offlineAndCardExpired",
                value: "The card is expired and offline mode is active.",
                comment: "Error message when the card is expired and offline mode is active."
            )

        case .offlineTransactionDeclined:
            return NSLocalizedString(
                "hardware.cardReader.underlyingError.offlineTransactionDeclined",
                value: "The offline transaction was declined.",
                comment: "Error message when the offline transaction was declined."
            )

        case .offlineCollectAndConfirmMismatch:
            return NSLocalizedString(
                "hardware.cardReader.underlyingError.offlineCollectAndConfirmMismatch",
                value: "There is a mismatch between offline collect and confirm.",
                comment: "Error message when there is a mismatch between offline collect and confirm."
            )

        case .onlinePinNotSupportedOffline:
            return NSLocalizedString(
                "hardware.cardReader.underlyingError.onlinePinNotSupportedOffline",
                value: "Online PIN is not supported in offline mode.",
                comment: "Error message when online PIN is not supported in offline mode."
            )

        case .offlineTestCardInLivemode:
            return NSLocalizedString(
                "hardware.cardReader.underlyingError.offlineTestCardInLivemode",
                value: "A test card is used in live mode while offline.",
                comment: "Error message when a test card is used in live mode while offline."
            )

        case .stripeAPIResponseDecodingError:
            return NSLocalizedString(
                "hardware.cardReader.underlyingError.stripeAPIResponseDecodingError",
                value: "There is an error decoding the Stripe API response.",
                comment: "Error message when there is an error decoding the Stripe API response."
            )

        case .internalNetworkError:
            return NSLocalizedString(
                "hardware.cardReader.underlyingError.internalNetworkError",
                value: "An internal network error occurred.",
                comment: "Error message when an internal network error occurs."
            )

        case .connectionTokenProviderCompletedWithError:
            return NSLocalizedString(
                "hardware.cardReader.underlyingError.connectionTokenProviderCompletedWithError",
                value: "The connection token provider finished with an error.",
                comment: "Error message when the connection token provider finishes with an error."
            )

        case .connectionTokenProviderTimedOut:
            return NSLocalizedString(
                "hardware.cardReader.underlyingError.connectionTokenProviderTimedOut",
                value: "The connection token provider operation timed out.",
                comment: "Error message when the connection token provider operation times out."
            )

        case .notConnectedToInternetAndOfflineBehaviorRequireOnline:
            return NSLocalizedString(
                "hardware.cardReader.underlyingError.notConnectedToInternetAndOfflineBehaviorRequireOnline",
                value: "Not connected to the internet, but online behavior is required.",
                comment: "Error message when not connected to the internet, but online behavior is required."
            )
        }
    }
}
