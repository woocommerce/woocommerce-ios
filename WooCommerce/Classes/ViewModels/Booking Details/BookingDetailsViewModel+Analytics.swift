import enum Networking.BookingAttendanceStatus

extension WooAnalyticsEvent {
    enum BookingsDetail {
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
    }
}

fileprivate extension WooAnalyticsEvent.BookingsDetail {
    enum Properties {
        static let bookingStatus = "booking_status"
    }
}
