import Foundation

/// This struct represents an analytics event. It is a combination of `WooAnalyticsStat` and
/// its properties.
///
/// This was mostly created to promote static-typing via constructors.
///
/// ## Adding New Events
///
/// 1. Add the event name (`String`) to `WooAnalyticsStat`.
/// 2. Create an `extension` of `WooAnalyticsStat` if necessary for grouping.
/// 3. Add a `static func` constructor.
///
/// Here is an example:
///
/// ~~~
/// extension WooAnalyticsEvent {
///     enum LoginStep: String {
///         case start
///         case success
///     }
///
///     static func login(step: LoginStep) -> WooAnalyticsEvent {
///         let properties = [
///             "step": step.rawValue
///         ]
///
///         return WooAnalyticsEvent(name: "login", properties: properties)
///     }
/// }
/// ~~~
///
/// Examples of tracking calls (in the client App or Pod):
///
/// ~~~
/// Analytics.track(event: .login(step: .start))
/// Analytics.track(event: .loginStart)
/// ~~~
///
public struct WooAnalyticsEvent {
    public let statName: WooAnalyticsStat
    public let properties: [String: WooAnalyticsEventPropertyType]
    public let error: Error?

    public init(statName: WooAnalyticsStat, properties: [String: WooAnalyticsEventPropertyType] = [:], error: Error? = nil) {
        self.statName = statName
        self.properties = properties
        self.error = error
    }
}

// MARK: - Local Catalog Analytics Events
extension WooAnalyticsEvent {
    /// Analytics events for Local Catalog feature
    public enum LocalCatalog {
        /// Event property Key.
        private enum Key {
            static let hoursSinceLastSync = "hours_since_last_sync"
            static let syncType = "sync_type"
            static let connectionType = "connection_type"
            static let productsSynced = "products_synced"
            static let variationsSynced = "variations_synced"
            static let totalProducts = "total_products"
            static let totalVariations = "total_variations"
            static let syncDurationMs = "sync_duration_ms"
            static let errorType = "error_type"
            static let reason = "reason"
        }

        // MARK: - Initial Launch & Loading Screen Events

        public static func downloadingScreenShown() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleLocalCatalogDownloadingScreenShown, properties: [:])
        }

        public static func downloadingScreenExitPosTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleLocalCatalogDownloadingScreenExitPosTapped, properties: [:])
        }

        public static func splashScreenErrorShown() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleSplashScreenErrorShown, properties: [:])
        }

        public static func splashScreenRetryTapped() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleSplashScreenRetryTapped, properties: [:])
        }

        // MARK: - Stale Catalog Warning Events

        public static func staleWarningShown(hoursSinceLastSync: Int) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleLocalCatalogStaleWarningShown,
                              properties: [Key.hoursSinceLastSync: "\(hoursSinceLastSync)"])
        }

        public static func staleWarningDismissed() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleLocalCatalogStaleWarningDismissed, properties: [:])
        }

        // MARK: - Sunset Warning Events

        public static func sunsetWarningShown() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleLocalCatalogSunsetWarningShown, properties: [:])
        }

        public static func sunsetWarningDismissed() -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleLocalCatalogSunsetWarningDismissed, properties: [:])
        }

        // MARK: - Core Sync Events

        public static func syncStarted(syncType: String, connectionType: String) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleLocalCatalogSyncStarted,
                              properties: [
                                Key.syncType: syncType,
                                Key.connectionType: connectionType
                              ])
        }

        public static func syncCompleted(
            syncType: String,
            productsSynced: Int,
            variationsSynced: Int,
            totalProducts: Int,
            totalVariations: Int,
            syncDurationMs: Int
        ) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleLocalCatalogSyncCompleted,
                              properties: [
                                Key.syncType: syncType,
                                Key.productsSynced: "\(productsSynced)",
                                Key.variationsSynced: "\(variationsSynced)",
                                Key.totalProducts: "\(totalProducts)",
                                Key.totalVariations: "\(totalVariations)",
                                Key.syncDurationMs: "\(syncDurationMs)"
                              ])
        }

        public static func syncFailed(
            syncType: String,
            error: Error,
            errorClassifier: (Error) -> String
        ) -> WooAnalyticsEvent {
            let errorType = errorClassifier(error)
            return WooAnalyticsEvent(statName: .pointOfSaleLocalCatalogSyncFailed,
                                     properties: [
                                        Key.syncType: syncType,
                                        Key.errorType: errorType
                                     ],
                                     error: error)
        }

        public static func syncSkipped(reason: String, syncType: String) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleLocalCatalogSyncSkipped,
                              properties: [Key.reason: reason,
                                           Key.syncType: syncType])
        }
    }
}
