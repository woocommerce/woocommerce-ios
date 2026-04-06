import Foundation
import enum NetworkingCore.OrderStatusEnum

/// Payment status resolved from the `_payment_status` order metadata.
///
/// Matches the web dashboard behavior which uses this metadata to determine payment status badges.
/// When the metadata is missing, defaults to `.unpaid`.
///
public enum BookingPaymentStatus: Equatable, Sendable {
    case paid
    case unpaid
    case failed
    case refunded
    case partiallyRefunded
    case authorized
    case authorizationVoided

    /// Resolves payment status from the `_payment_status` order metadata value.
    ///
    /// - Parameter paymentStatusMetadata: The raw string value from `_payment_status` metadata.
    ///   When `nil` or unrecognized, defaults to `.unpaid` (matching web behavior).
    public init(paymentStatusMetadata: String?) {
        switch paymentStatusMetadata {
        case "paid":
            self = .paid
        case "unpaid":
            self = .unpaid
        case "failed":
            self = .failed
        case "refunded":
            self = .refunded
        case "partially_refunded":
            self = .partiallyRefunded
        case "authorized":
            self = .authorized
        case "authorization_voided":
            self = .authorizationVoided
        default:
            self = .unpaid
        }
    }
}
