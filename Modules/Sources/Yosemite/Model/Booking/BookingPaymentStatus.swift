import Foundation
import enum NetworkingCore.OrderStatusEnum

/// Payment status resolved from order data associated with a booking.
///
/// Matches the Android `WooPosPaymentStatusResolver` logic.
/// Both POS and Store Management booking screens use this type,
/// passing whichever order fields they have available.
///
/// Priority:
/// 1. refundTotal > 0 && refundTotal >= total → refunded
/// 2. refundTotal > 0 → partiallyRefunded
/// 3. orderStatus == .refunded → refunded (fallback when refund amounts unavailable)
/// 4. datePaid != nil → paid
/// 5. orderStatus == .failed || .cancelled → failed
/// 6. else → unpaid
///
public enum BookingPaymentStatus: Equatable, Sendable {
    case paid
    case unpaid
    case failed
    case refunded
    case partiallyRefunded

    /// Resolves payment status from raw order fields.
    ///
    /// - Parameters:
    ///   - orderStatusKey: The raw order status string (e.g. "processing", "refunded").
    ///   - datePaid: When the order was paid, if ever.
    ///   - refundTotal: Total amount refunded. Defaults to 0 when unavailable.
    ///   - total: Order total. Defaults to 0 when unavailable.
    public init(orderStatusKey: String,
                datePaid: Date?,
                refundTotal: Decimal = 0,
                total: Decimal = 0) {
        let orderStatus = OrderStatusEnum(rawValue: orderStatusKey)

        if refundTotal > 0, refundTotal >= total {
            self = .refunded
        } else if refundTotal > 0 {
            self = .partiallyRefunded
        } else if orderStatus == .refunded {
            self = .refunded
        } else if datePaid != nil {
            self = .paid
        } else if orderStatus == .failed || orderStatus == .cancelled {
            self = .failed
        } else {
            self = .unpaid
        }
    }
}
