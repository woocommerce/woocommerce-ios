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

    /// Error thrown while disonnecting from a reader
    case disconnection(underlyingError: UnderlyingError = .internalServiceError)

    /// Error thrown while creating a payment intent
    case intentCreation(underlyingError: UnderlyingError = .internalServiceError)

    /// Error thrown while collecting payment methods
    case paymentMethodCollection(underlyingError: UnderlyingError = .internalServiceError)

    /// Error thrown while capturing a payment
    case paymentCapture(underlyingError: UnderlyingError = .internalServiceError)

    /// Error thrown while cancelling a payment
    case paymentCancellation(underlyingError: UnderlyingError = .internalServiceError)

    /// Error thrown while updating the reader firmware
    case softwareUpdate(underlyingError: UnderlyingError = .internalServiceError, batteryLevel: Double?)

    /// The user has denied the app permission to use Bluetooth
    case bluetoothDenied
}

extension CardReaderServiceError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .connection(let underlyingError):
            return underlyingError.errorDescription
        case .discovery(let underlyingError):
            return underlyingError.errorDescription
        case .disconnection(let underlyingError):
            return underlyingError.errorDescription
        case .intentCreation(let underlyingError):
            return underlyingError.errorDescription
        case .paymentMethodCollection(let underlyingError):
            return underlyingError.errorDescription
        case .paymentCapture(let underlyingError):
            return underlyingError.errorDescription
        case .paymentCancellation(let underlyingError):
            return underlyingError.errorDescription
        case .softwareUpdate(let underlyingError, _):
            return underlyingError.errorDescription
        case .bluetoothDenied:
            return NSLocalizedString(
                "This app needs permission to access Bluetooth to connect to a card reader, please change the privacy settings if you wish to allow this.",
                comment: "Explanation in the alert presented when the user tries to connect a Bluetooth card reader with insufficient permissions"
            )
        }
    }
}
