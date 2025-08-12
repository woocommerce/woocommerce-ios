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

    enum POSCatalogSync {

        private enum Keys {
            static let duration = "duration"
            static let source = "source"
            static let taskType = "task_type"
        }

        // Scheduling events
        static func fullSyncScheduled() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .posFullCatalogSyncScheduled, properties: [:])
        }

        static func incrementalSyncScheduled() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .posIncrementalSyncScheduled, properties: [:])
        }

        static func schedulingError(_ error: Error, taskType: String) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .posCatalogSyncSchedulingError, properties: [Keys.taskType: taskType], error: error)
        }

        // Sync completion events
        static func fullSyncCompleted(source: String, duration: TimeInterval? = nil) -> WooAnalyticsEvent {
            var properties: [String: String] = [Keys.source: source]
            if let duration = duration {
                properties[Keys.duration] = String(duration)
            }
            return WooAnalyticsEvent(statName: .posFullCatalogSyncCompleted, properties: properties)
        }

        static func incrementalSyncCompleted(duration: TimeInterval) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .posIncrementalSyncCompleted, properties: [Keys.duration: duration])
        }

        // Sync error events
        static func fullSyncError(_ error: Error, source: String) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .posFullCatalogSyncError, properties: [Keys.source: source], error: error)
        }

        static func incrementalSyncError(_ error: Error) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .posIncrementalSyncError, properties: [:], error: error)
        }

        // Task management events
        static func taskExpired(taskType: String) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .posCatalogSyncTaskExpired, properties: [Keys.taskType: taskType])
        }

        static func syncRecovered() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .posCatalogSyncRecovered, properties: [:])
        }

        static func recoveryError(_ error: Error) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .posCatalogSyncRecoveryError, properties: [:], error: error)
        }
    }
}
