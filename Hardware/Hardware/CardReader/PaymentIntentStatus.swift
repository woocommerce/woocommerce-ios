import Codegen
import Foundation

/// The possible statuses for a PaymentIntent.
public enum PaymentIntentStatus: Equatable, GeneratedFakeable {
    case requiresPaymentMethod
    case requiresConfirmation
    case requiresCapture
    case processing
    case canceled
    case succeeded
}
