import struct WooFoundation.WooAnalyticsEvent

extension WooAnalyticsEvent {
    enum PointOfSaleIneligibleUI {
        /// Event property key.
        private enum Key {
            static let reason = "reason"
        }

        static func ineligibleUIShown(reason: POSIneligibleReason) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleIneligibleUIShown, properties: [Key.reason: reason.analyticsValue])
        }

        static func ineligibleUIRetryTapped(reason: POSIneligibleReason) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleIneligibleUIRetryTapped, properties: [Key.reason: reason.analyticsValue])
        }

        static func ineligibleUILearnMoreTapped(reason: POSIneligibleReason) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleIneligibleUILearnMoreTapped, properties: [Key.reason: reason.analyticsValue])
        }
    }
}

private extension POSIneligibleReason {
    var analyticsValue: String {
        switch self {
        case .unsupportedWooCommerceVersion:
            return "wc_plugin_version"
        case .wooCommercePluginNotFound:
            return "unknown_wc_plugin"
        case .siteSettingsNotAvailable,
             .selfDeallocated:
            return "other"
        }
    }
}
