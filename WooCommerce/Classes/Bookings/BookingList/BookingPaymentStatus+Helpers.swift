import Foundation
import enum Yosemite.BookingPaymentStatus

extension BookingPaymentStatus {
    var localizedTitle: String {
        switch self {
        case .paid:
            NSLocalizedString(
                "bookingPaymentStatus.title.paid",
                value: "Paid",
                comment: "Status of a paid booking"
            )
        case .unpaid:
            NSLocalizedString(
                "bookingPaymentStatus.title.unpaid",
                value: "Unpaid",
                comment: "Status of an unpaid booking"
            )
        case .refunded:
            NSLocalizedString(
                "bookingPaymentStatus.title.refunded",
                value: "Refunded",
                comment: "Status of a refunded booking"
            )
        case .unknown:
            NSLocalizedString(
                "bookingPaymentStatus.title.unknown",
                value: "Unknown",
                comment: "Status of a booking with unexpected payment status"
            )
        }
    }
}
