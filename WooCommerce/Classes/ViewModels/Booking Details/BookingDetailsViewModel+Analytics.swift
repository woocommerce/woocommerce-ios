extension WooAnalyticsEvent {
    enum BookingsDetail {
        static func bookingCancelled() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .bookingCancelled)
        }
    }
}
