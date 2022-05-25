import Codegen

/// The possible statuses for a PaymentIntent. The cases should match `WCPayPaymentIntentStatusEnum`.
public enum PaymentIntentStatus: Equatable, GeneratedFakeable {
    case requiresPaymentMethod
    case requiresConfirmation
    case requiresAction
    case requiresCapture
    case processing
    case canceled
    case succeeded
    case unknown
}
