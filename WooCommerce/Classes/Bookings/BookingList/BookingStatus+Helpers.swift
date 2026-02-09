import Foundation
import enum Networking.BookingStatus

extension BookingStatus {
    var localizedTitle: String {
        switch self {
        case .complete:
            NSLocalizedString(
                "bookingStatus.title.complete",
                value: "Complete",
                comment: "Status of a complete booking"
            )
        case .paid:
            NSLocalizedString(
                "bookingStatus.title.paid",
                value: "Paid",
                comment: "Status of a paid booking"
            )
        case .unpaid:
            NSLocalizedString(
                "bookingStatus.title.unpaid",
                value: "Unpaid",
                comment: "Status of an unpaid booking"
            )
        case .cancelled:
            NSLocalizedString(
                "bookingStatus.title.canceled",
                value: "Cancelled",
                comment: "Status of a canceled booking"
            )
        case .pendingConfirmation:
            NSLocalizedString(
                "bookingStatus.title.pendingConfirmation",
                value: "Pending confirmation",
                comment: "Status of a pending confirmation booking"
            )
        case .confirmed:
            NSLocalizedString(
                "bookingStatus.title.confirmed",
                value: "Confirmed",
                comment: "Status of a confirmed booking"
            )
        case .unknown:
            NSLocalizedString(
                "bookingStatus.title.unknown",
                value: "Unknown",
                comment: "Status of a booking with unexpected status"
            )
        }
    }
}
