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
            /// Strictly, 16.0 is required in the US, 16.4 in the UK... but it's overly complicated to make this country specific.
            /// Any device running 16.0 can run 16.4, so this seems clear enough.
            return NSLocalizedString("Please check that your phone meets these requirements: " +
                                     "iPhone XS or newer running iOS 16.4 or above. Contact support if this error " +
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
        }
    }
}
