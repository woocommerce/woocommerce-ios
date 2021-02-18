///The possible statuses for a PaymentIntent.
public enum PaymentIntentStatus {
    case requiresPaymentMethod
    case requiresConfirmation
    case requiresCapture
    case processing
    case canceled
    case succeeded
}
