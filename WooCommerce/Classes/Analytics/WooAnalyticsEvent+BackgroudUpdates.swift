import Foundation

extension WooAnalyticsEvent {
    enum BackgroundUpdates {

        private enum Keys {
            static let timeTaken = "time_taken"
        }

        static func dataSynced(timeTaken: TimeInterval) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .backgroundDataSynced, properties: [Keys.timeTaken: timeTaken])
        }

        static func dataSyncError(_ error: Error) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .backgroundDataSyncError, properties: [:], error: error)
        }

        static func orderPushNotificationSynced(timeTaken: TimeInterval) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pushNotificationOrderBackgroundSynced, properties: [Keys.timeTaken: timeTaken])
        }

        static func orderPushNotificationSyncError(_ error: Error) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pushNotificationOrderBackgroundSyncError, properties: [:], error: error)
        }

        static func disabled() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .backgroundUpdatesDisabled, properties: [:])
        }
    }
}
