import Foundation
import Yosemite

extension WooAnalyticsEvent {
    enum PushNotifications {
        /// Tracked when the self-driven push token is successfully registered for a specific target site.
        /// Emits the target site's analytics properties so per-site dashboards attribute the event to the
        /// correct site instead of the currently selected one.
        static func wooPushTokenRegisterSuccess(targetSite: Site?) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .wooPushTokenRegisterSuccess,
                              properties: targetSite?.analyticsProperties ?? [:])
        }

        /// Tracked when the self-driven push token registration fails for a specific target site.
        /// Emits the target site's analytics properties so per-site dashboards attribute the event to the
        /// correct site instead of the currently selected one.
        static func wooPushTokenRegisterError(targetSite: Site?, error: Error) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .wooPushTokenRegisterError,
                              properties: targetSite?.analyticsProperties ?? [:],
                              error: error)
        }
    }
}
