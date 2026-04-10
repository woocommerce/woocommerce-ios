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
            static let syncStrategy = "sync_strategy"
            static let connectionType = "connection_type"
            static let productsSynced = "products_synced"
            static let variationsSynced = "variations_synced"
            static let totalProducts = "total_products"
            static let totalVariations = "total_variations"
            static let syncDurationMs = "sync_duration_ms"
            static let generationDurationMs = "generation_duration_ms"
            static let pollAttempts = "poll_attempts"
            static let lastGenerationState = "last_generation_state"
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

        public static func syncStarted(syncType: String, syncStrategy: String, connectionType: String) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleLocalCatalogSyncStarted,
                              properties: [
                                Key.syncType: syncType,
                                Key.syncStrategy: syncStrategy,
                                Key.connectionType: connectionType
                              ])
        }

        public static func syncCompleted(
            syncType: String,
            syncStrategy: String,
            productsSynced: Int,
            variationsSynced: Int,
            totalProducts: Int,
            totalVariations: Int,
            syncDurationMs: Int,
            generationDurationMs: Int? = nil,
            pollAttempts: Int? = nil
        ) -> WooAnalyticsEvent {
            var properties: [String: WooAnalyticsEventPropertyType] = [
                Key.syncType: syncType,
                Key.syncStrategy: syncStrategy,
                Key.productsSynced: "\(productsSynced)",
                Key.variationsSynced: "\(variationsSynced)",
                Key.totalProducts: "\(totalProducts)",
                Key.totalVariations: "\(totalVariations)",
                Key.syncDurationMs: "\(syncDurationMs)"
            ]
            if let generationDurationMs {
                properties[Key.generationDurationMs] = "\(generationDurationMs)"
            }
            if let pollAttempts {
                properties[Key.pollAttempts] = "\(pollAttempts)"
            }
            return WooAnalyticsEvent(statName: .pointOfSaleLocalCatalogSyncCompleted, properties: properties)
        }

        public static func syncFailed(
            syncType: String,
            syncStrategy: String,
            error: Error,
            errorClassifier: (Error) -> String,
            pollAttempts: Int? = nil,
            lastGenerationState: String? = nil
        ) -> WooAnalyticsEvent {
            let errorType = errorClassifier(error)
            var properties: [String: WooAnalyticsEventPropertyType] = [
                Key.syncType: syncType,
                Key.syncStrategy: syncStrategy,
                Key.errorType: errorType
            ]
            if let pollAttempts {
                properties[Key.pollAttempts] = "\(pollAttempts)"
            }
            if let lastGenerationState {
                properties[Key.lastGenerationState] = lastGenerationState
            }
            return WooAnalyticsEvent(statName: .pointOfSaleLocalCatalogSyncFailed, properties: properties, error: error)
        }

        public static func syncSkipped(reason: String, syncType: String, syncStrategy: String) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleLocalCatalogSyncSkipped,
                              properties: [Key.reason: reason,
                                           Key.syncType: syncType,
                                           Key.syncStrategy: syncStrategy])
        }
    }
}
