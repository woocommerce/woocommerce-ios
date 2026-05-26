import protocol WooFoundationCore.WooAnalyticsEventPropertyType

extension WooAnalyticsEvent {
    enum BookingsDetail {
        private enum Properties {
            static let action = "action"
        }

        enum Action: String {
            case cancelBooking = "cancel_booking"
            case updateAttendance = "update_attendance"
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
