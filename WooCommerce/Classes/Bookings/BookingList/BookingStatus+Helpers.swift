import Foundation
import enum Networking.BookingStatus

extension BookingStatus {
    var localizedTitle: String {
        switch self {
        case .booked:
            NSLocalizedString(
                "bookingStatus.title.booked",
                value: "Booked",
                comment: "Status of a booked booking"
            )
        case .completed:
            NSLocalizedString(
                "bookingStatus.title.completed",
                value: "Completed",
                comment: "Status of a completed booking"
            )
        case .cancelled:
            NSLocalizedString(
                "bookingStatus.title.canceled",
                value: "Cancelled",
                comment: "Status of a canceled booking"
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
