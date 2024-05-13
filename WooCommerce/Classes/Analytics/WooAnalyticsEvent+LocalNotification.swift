import protocol WooFoundation.WooAnalyticsEventPropertyType

extension WooAnalyticsEvent {
    enum LocalNotification {
        /// Event property keys.
        enum Key {
            static let type = "type"
            static let isIAPAvailable = "is_iap_available"
        }

        static func tapped(type: String, userInfo: [AnyHashable: Any]) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .localNotificationTapped,
                              properties: getTracksProperties(type: type, userInfo: userInfo))
        }

        static func dismissed(type: String, userInfo: [AnyHashable: Any]) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .localNotificationDismissed,
                              properties: getTracksProperties(type: type, userInfo: userInfo))
        }

        static func scheduled(type: String, userInfo: [AnyHashable: Any]) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .localNotificationScheduled,
                                     properties: getTracksProperties(type: type, userInfo: userInfo))
        }

        static func canceled(type: String, userInfo: [AnyHashable: Any]) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .localNotificationCanceled,
                                     properties: getTracksProperties(type: type, userInfo: userInfo))
        }

        /// Helper method to build properties dictionary
        ///
        static private func getTracksProperties(type: String, userInfo: [AnyHashable: Any]) -> [String: WooAnalyticsEventPropertyType] {
            var properties: [String: WooAnalyticsEventPropertyType] = [Key.type: type]
            if let isIapAvailable = userInfo[Key.isIAPAvailable] as? Bool {
                properties[Key.isIAPAvailable] = isIapAvailable
            }
            return properties
        }
    }
}
