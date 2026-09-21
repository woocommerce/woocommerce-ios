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

        /// Tracked when the self-driven push token is successfully deleted for a specific target site.
        /// Emits the target site's analytics properties so per-site dashboards attribute the event to the
        /// correct site instead of the currently selected one.
        static func wooPushTokenDeleteSuccess(targetSite: Site?) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .wooPushTokenDeleteSuccess,
                              properties: properties(for: targetSite))
        }

        /// Tracked when the self-driven push token deletion fails for a specific target site.
        /// Emits the target site's analytics properties so per-site dashboards attribute the event to the
        /// correct site instead of the currently selected one.
        static func wooPushTokenDeleteError(targetSite: Site?, error: Error) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .wooPushTokenDeleteError,
                              properties: properties(for: targetSite),
                              error: error)
        }

        /// Tracked when a push notification arrives in any app state other than being opened from the
        /// notification. Attributes `blog_id` / `site_url` to the notification's origin site rather than
        /// the currently selected one.
        static func pushNotificationReceived(originSiteID: Int64?,
                                             originSite: Site?,
                                             properties: [String: WooAnalyticsEventPropertyType]) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pushNotificationReceived,
                              properties: originSiteProperties(originSiteID: originSiteID, originSite: originSite, merging: properties))
        }

        /// Tracked when the user opens the app by tapping a push notification. Attributes `blog_id` /
        /// `site_url` to the notification's origin site rather than the currently selected one.
        static func pushNotificationAlertPressed(originSiteID: Int64?,
                                                 originSite: Site?,
                                                 properties: [String: WooAnalyticsEventPropertyType]) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pushNotificationAlertPressed,
                              properties: originSiteProperties(originSiteID: originSiteID, originSite: originSite, merging: properties))
        }

        /// Builds properties for an event about the notification's origin site. When the origin site isn't
        /// available locally (e.g. a store no longer in the account), `blog_id` still carries the payload's
        /// site ID so the origin is never lost. Note that `store_id` and `cached_woo_core_version` still
        /// describe the selected session store, matching the token register/delete events.
        private static func originSiteProperties(originSiteID: Int64?,
                                                 originSite: Site?,
                                                 merging eventProperties: [String: WooAnalyticsEventPropertyType]) -> [String: WooAnalyticsEventPropertyType] {
            var properties = properties(for: originSite)
            if originSite == nil, let originSiteID {
                properties[Site.PropertyKeys.blogID] = originSiteID
            }
            return properties.merging(eventProperties) { _, event in event }
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
