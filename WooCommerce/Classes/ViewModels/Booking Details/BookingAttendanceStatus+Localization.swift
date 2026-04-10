import Foundation
import Networking

extension BookingAttendanceStatus {
    var localizedTitle: String {
        switch self {
        case .attended:
            return NSLocalizedString(
                "BookingAttendanceStatus.attended",
                value: "Attended",
                comment: "Title for 'Attended' booking attendance status."
            )
        case .unattended:
            return NSLocalizedString(
                "BookingAttendanceStatus.unattended",
                value: "Unattended",
                comment: "Title for 'Unattended' booking attendance status."
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
