/// Models errors thrown by the CardReaderService.
/// It identifies the interaction with the card reader
/// where the error was thrown.
/// It is important to mark the specific interaction
/// because some operations (like, for example, processing a payment)
/// require three interactions with the SDK in sequence, and any error
/// in any of the steps in that sequence would make the whole operation fail
public enum CardReaderServiceError: Error {
    /// Error thrown during reader discovery
    case discovery(underlyingError: UnderlyingError = .internalServiceError)

    /// Error thrown while connecting to a reader
    case connection(underlyingError: UnderlyingError = .internalServiceError)

    /// Error thrown while creating a payment intent
    case intentCreation(underlyingError: UnderlyingError = .internalServiceError)

    /// Error thrown while collecting payment methods
    case paymentMethodCollection(underlyingError: UnderlyingError = .internalServiceError)

    /// Error thrown while capturing a payment
    case paymentCapture(underlyingError: UnderlyingError = .internalServiceError)
}


/// Underlying error. Models the specific error that made a given
/// interaction with the SDK fail.
public enum UnderlyingError: Error {
    /// The service is busy executing another command. The service can only execute a single command at a time.
    case busy

    /// No reader is connected. Connect to a reader before trying again.
    case notConnectedToReader

    /// Already connected to a reader.
    case alreadyConnectedToReader

    /// Attempted to process a nil or invalid payment intent
    case processInvalidPaymentIntent

    /// Attempted to connect to a reader that has not been discovered yet
    case connectingToUndiscoveredReader

    /// Attempted to connect from an unsupported version of the SDK.
    /// In order to fix this you will need to update your app
    /// to the most recent version of the SDK.
    case unsupportedSDK

    /// This feature is currently not available for the selected reader.
    /// e.g.: attempting to create a local payment intent on a reader that
    /// requires the payment intent to be created on the backend
    case featureNotAvailableWithConnectedReader

    /// A command was cancelled
    case commandCancelled

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
    case paymentDeclinedByPaymentProcessorAPI

    /// The reader declined the payment. Try another card.
    case paymentDeclinedByCardReader

    /// The SDK is not connected to the internet.
    case notConnectedToInternet

    /// The underlying request timed out.
    case requestTimedOut

    /// The current session has expired and the reader must be disconnected and reconnected.
    /// The SDK will attempt to auto-disconnect for you and you should instruct your user to reconnect it.
    case readerSessionExpired

    /// Catch-all error case. Indicates there is something wrong with the
    /// internal state of the CardReaderService.
    case internalServiceError
}
