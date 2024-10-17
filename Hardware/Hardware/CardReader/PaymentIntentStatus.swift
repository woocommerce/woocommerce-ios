import Codegen

/// The possible statuses for a PaymentIntent.
public enum PaymentIntentStatus: Equatable, GeneratedFakeable, Codable {
    case requiresPaymentMethod
    case requiresConfirmation
    case requiresCapture
    case processing
    case canceled
    case succeeded
}
