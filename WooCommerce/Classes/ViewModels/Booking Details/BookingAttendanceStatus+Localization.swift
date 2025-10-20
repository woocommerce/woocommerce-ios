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
                value: "Checked In",
                comment: "Title for 'Checked In' booking attendance status."
            )
        case .cancelled:
            return NSLocalizedString(
                "BookingAttendanceStatus.cancelled",
                value: "Cancelled",
                comment: "Title for 'Cancelled' booking attendance status."
            )
        case .noShow:
            return NSLocalizedString(
                "BookingAttendanceStatus.noShow",
                value: "No Show",
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
