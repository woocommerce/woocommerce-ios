import enum Networking.BookingAttendanceStatus

extension WooAnalyticsEvent {
    enum BookingsDetail {
        private enum Properties {
            static let bookingStatus = "booking_status"
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

        static func bookingMarkAsPaidTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .bookingMarkAsPaidTapped)
        }

        static func bookingViewLinkedOrderTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .bookingViewLinkedOrderTapped)
        }
    }
}
