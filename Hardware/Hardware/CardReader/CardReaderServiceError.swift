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

    /// Error thrown while disconnecting from a reader
    case disconnection(underlyingError: UnderlyingError = .internalServiceError)

    /// Error thrown while creating a payment intent
    case intentCreation(underlyingError: UnderlyingError = .internalServiceError)

    /// Error thrown while collecting payment methods
    case paymentMethodCollection(underlyingError: UnderlyingError = .internalServiceError)

    /// Error thrown while capturing a payment
    case paymentCapture(underlyingError: UnderlyingError = .internalServiceError)

    /// Error thrown when the order payment fails to be captured with a known payment method.
    /// The payment method is currently used for analytics.
    case paymentCaptureWithPaymentMethod(underlyingError: UnderlyingError, paymentMethod: PaymentMethod)

    /// Error thrown while cancelling a payment
    case paymentCancellation(underlyingError: UnderlyingError = .internalServiceError)

    /// Error thrown while setting up a refund
    case refundCreation(underlyingError: UnderlyingError = .internalServiceError)

    /// Error thrown while refunding a payment
    case refundPayment(underlyingError: UnderlyingError = .internalServiceError, shouldRetry: Bool)

    /// Error thrown while cancelling a refund
    case refundCancellation(underlyingError: UnderlyingError = .internalServiceError)

    /// Error thrown while updating the reader firmware
    case softwareUpdate(underlyingError: UnderlyingError = .internalServiceError, batteryLevel: Double?)

    /// The user has denied the app permission to use Bluetooth
    case bluetoothDenied

    case retryNotPossibleNoActivePayment

    case retryNotPossibleActivePaymentCancelled

    case retryNotPossibleActivePaymentSucceeded

    case retryNotPossibleProcessingInProgress

    case retryNotPossibleRequiresAction

    case retryNotPossibleUnknownCause
}

extension CardReaderServiceError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .connection(let underlyingError),
                .discovery(let underlyingError),
                .disconnection(let underlyingError),
                .intentCreation(let underlyingError),
                .paymentMethodCollection(let underlyingError),
                .paymentCapture(let underlyingError),
                .paymentCancellation(let underlyingError),
                .refundCreation(let underlyingError),
                .refundPayment(let underlyingError, _),
                .refundCancellation(let underlyingError),
                .softwareUpdate(let underlyingError, _):
            return underlyingError.errorDescription
        case .paymentCaptureWithPaymentMethod(underlyingError: let underlyingError, paymentMethod: _):
            return underlyingError.errorDescription ?? underlyingError.localizedDescription
        case .bluetoothDenied:
            return NSLocalizedString(
                "This app needs permission to access Bluetooth to connect to a card reader, please change the privacy settings if you wish to allow this.",
                comment: "Explanation in the alert presented when the user tries to connect a Bluetooth card reader with insufficient permissions"
            )
        case .retryNotPossibleNoActivePayment,
                .retryNotPossibleActivePaymentCancelled,
                .retryNotPossibleProcessingInProgress,
                .retryNotPossibleRequiresAction,
                .retryNotPossibleUnknownCause:
            return NSLocalizedString(
                "We were unable to retry the payment – please start again.",
                comment: "Explanation in the alert presented when a retry of a payment fails"
            )
        case .retryNotPossibleActivePaymentSucceeded:
            return NSLocalizedString(
                "This payment has already been completed – please check the order details.",
                comment: "Explanation in the alert shown when a retry fails because the payment already completed")
        }
    }
}
