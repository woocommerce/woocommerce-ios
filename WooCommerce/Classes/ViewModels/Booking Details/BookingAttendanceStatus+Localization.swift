import Foundation
import Networking

extension BookingAttendanceStatus {
    var localizedTitle: String {
        switch self {
        case .booked:
            return NSLocalizedString(
                "BookingAttendanceStatus.booked",
                value: "Booked",
                comment: "Title for 'Booked' booking attendance status."
            )
        case .checkedIn:
            return NSLocalizedString(
                "BookingAttendanceStatus.checkedIn",
                value: "Checked-in",
                comment: "Title for 'Checked In' booking attendance status."
            )
        case .cancelled:
            return NSLocalizedString(
                "BookingAttendanceStatus.canceled",
                value: "Canceled",
                comment: "Title for 'Cancelled' booking attendance status."
            )
        case .noShow:
            return NSLocalizedString(
                "BookingAttendanceStatus.noShow",
                value: "No-show",
                comment: "Title for 'No Show' booking attendance status."
            )
        case .unknown:
            return NSLocalizedString(
                "BookingAttendanceStatus.unknown",
                value: "Unknown",
                comment: "Title for 'Unknown' booking attendance status."
            )
        }
    }
}
