import Foundation
import WooFoundation

extension WooAnalyticsEvent {
    enum BackgroundUpdates {

        private enum Keys {
            static let timeTaken = "time_taken"
            static let backgroundTimeGranted = "background_time_granted"
            static let networkType = "network_type"
            static let isExpensiveConnection = "is_expensive_connection"
            static let isLowDataMode = "is_low_data_mode"
            static let isPowered = "is_powered"
            static let batteryLevel = "battery_level"
            static let isLowPowerMode = "is_low_power_mode"
            static let timeSinceLastRun = "time_since_last_run"
        }

        static func dataSynced(
            timeTaken: TimeInterval,
            backgroundTimeGranted: TimeInterval?,
            networkType: String,
            isExpensiveConnection: Bool,
            isLowDataMode: Bool,
            isPowered: Bool,
            batteryLevel: Float,
            isLowPowerMode: Bool,
            timeSinceLastRun: TimeInterval?
        ) -> WooAnalyticsEvent {
            var properties: [String: WooAnalyticsEventPropertyType] = [
                Keys.timeTaken: Int64(timeTaken),
                Keys.networkType: networkType,
                Keys.isExpensiveConnection: isExpensiveConnection,
                Keys.isLowDataMode: isLowDataMode,
                Keys.isPowered: isPowered,
                Keys.batteryLevel: Float64(batteryLevel),
                Keys.isLowPowerMode: isLowPowerMode
            ]

            if let backgroundTimeGranted {
                properties[Keys.backgroundTimeGranted] = Int64(backgroundTimeGranted)
            }

            if let timeSinceLastRun {
                properties[Keys.timeSinceLastRun] = Int64(timeSinceLastRun)
            }

            return WooAnalyticsEvent(statName: .backgroundDataSynced, properties: properties)
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
