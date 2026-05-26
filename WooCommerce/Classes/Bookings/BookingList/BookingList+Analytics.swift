extension WooAnalyticsEvent {
    enum BookingList {
        static func failedToFetchBookings(_ error: Error) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .bookingListFailedToFetchBookings,
                              error: error)
        }
    }
}
