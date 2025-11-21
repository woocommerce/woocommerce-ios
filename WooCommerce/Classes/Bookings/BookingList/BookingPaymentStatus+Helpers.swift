import Foundation
import enum Yosemite.BookingPaymentStatus

extension BookingPaymentStatus {
    var localizedTitle: String {
        switch self {
        case .unpaid:
            NSLocalizedString(
                "bookingPaymentStatus.title.unpaid",
                value: "Unpaid",
                comment: "Display label for unpaid payment status."
            )
        case .paid:
            NSLocalizedString(
                "bookingPaymentStatus.title.paid",
                value: "Paid",
                comment: "Display label for paid payment status."
            )
        case .partiallyRefunded:
            NSLocalizedString(
                "bookingPaymentStatus.title.partiallyRefunded",
                value: "Partially Refunded",
                comment: "Display label for partially refunded payment status."
            )
        case .refunded:
            NSLocalizedString(
                "bookingPaymentStatus.title.refunded",
                value: "Refunded",
                comment: "Display label for refunded payment status."
            )
        case .failed:
            NSLocalizedString(
                "bookingPaymentStatus.title.failed",
                value: "Failed",
                comment: "Display label for failed payment status."
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
