extension WooAnalyticsEvent {
    enum WPCOMSiteSuspended {
        enum Event: String {
            case login = "login"
            case appLaunch = "app_launch"
        }

        /// Event property keys.
        private enum Keys {
            static let event = "event"
        }

        /// Tracked when a WPCOM suspended site is detected.
        ///
        static func siteSuspended(event: Event) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .blackFlaggedWebsiteDetected, properties: [Keys.event: event.rawValue])
        }
    }
}
