import protocol WooFoundationCore.WooAnalyticsEventPropertyType
import enum Networking.BookingAttendanceStatus

extension WooAnalyticsEvent {
    enum BookingsDetail {
        private enum Properties {
            static let bookingStatus = "booking_status"
            static let action = "action"
        }

        enum Action: String {
            case cancelBooking = "cancel_booking"
            case updateAttendance = "update_attendance"
            case markAsPaid = "mark_as_paid"
        }

        static func bookingCancelled() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .bookingDetailCancelBooking)
        }

        static func attendanceStatusUpdate(status: BookingAttendanceStatus) -> WooAnalyticsEvent {
            WooAnalyticsEvent(
                statName: .bookingDetailAttendanceStatusUpdate,
                properties: [Properties.bookingStatus: status.rawValue]
            )
        }

        static func addNoteTap() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .bookingDetailAddNoteTap)
        }

        static func viewLinkedOrderTap() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .bookingDetailViewLinkedOrderTap)
        }

        // TODO: Wire up tracking call when mark-as-paid feature is added to BookingDetailsViewModel
        static func markAsPaidTap() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .bookingDetailMarkAsPaidTap)
        }

        // TODO: Wire up tracking call when refund feature is added to BookingDetailsViewModel
        static func refundTap() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .bookingDetailRefundTap)
        }

        static func failedToUpdateBookingDetails(action: Action, error: Error) -> WooAnalyticsEvent {
            let properties: [String: WooAnalyticsEventPropertyType] = [
                Properties.action: action.rawValue
            ]
            return  WooAnalyticsEvent(statName: .bookingListFailedToUpdateBookingDetails,
                                      properties: properties,
                                      error: error)
        }
    }
}
