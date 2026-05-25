import Foundation
import Yosemite
import protocol WooFoundation.WooAnalyticsEventPropertyType

extension WooAnalyticsEvent {
    enum PushNotifications {
        /// Tracked when the self-driven push token is successfully registered for a specific target site.
        /// Emits the target site's analytics properties so per-site dashboards attribute the event to the
        /// correct site instead of the currently selected one.
        static func wooPushTokenRegisterSuccess(targetSite: Site?) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .wooPushTokenRegisterSuccess,
                              properties: properties(for: targetSite))
        }

        /// Tracked when the self-driven push token registration fails for a specific target site.
        /// Emits the target site's analytics properties so per-site dashboards attribute the event to the
        /// correct site instead of the currently selected one.
        static func wooPushTokenRegisterError(targetSite: Site?, error: Error) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .wooPushTokenRegisterError,
                              properties: properties(for: targetSite),
                              error: error)
        }

        /// Combines the target site's analytics properties with session-level fields (`store_id`,
        /// `cached_woo_core_version`) that the default-site enrichment would normally attach.
        /// These events opt out of that enrichment to protect the target-site attribution, so the
        /// session fields are re-added here to preserve the pre-existing payload shape.
        private static func properties(for targetSite: Site?) -> [String: WooAnalyticsEventPropertyType] {
            var properties: [String: WooAnalyticsEventPropertyType] = targetSite?.analyticsProperties ?? [:]
            let sessionManager = ServiceLocator.stores.sessionManager
            if let storeID = sessionManager.defaultStoreUUID {
                properties[SessionPropertyKeys.storeID] = storeID
            }
            if let cachedWooCoreVersion = sessionManager.cachedWooCommerceVersion {
                properties[SessionPropertyKeys.cachedWooCoreVersion] = cachedWooCoreVersion
            }
            return properties
        }

        private enum SessionPropertyKeys {
            static let storeID = "store_id"
            static let cachedWooCoreVersion = "cached_woo_core_version"
        }
    }
}
