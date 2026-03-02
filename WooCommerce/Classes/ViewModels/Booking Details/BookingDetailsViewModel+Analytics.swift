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
        }

        static func bookingCancelled() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .bookingCancelled)
        }

        static func bookingAttenceStatusUpdated(status: BookingAttendanceStatus) -> WooAnalyticsEvent {
            WooAnalyticsEvent(
                statName: .bookingAttenceStatusUpdated,
                properties: [Properties.bookingStatus: status.rawValue]
            )
        }

        static func bookingAddNoteTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .bookingAddNoteTapped)
        }

        static func bookingViewLinkedOrderTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .bookingViewLinkedOrderTapped)
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
