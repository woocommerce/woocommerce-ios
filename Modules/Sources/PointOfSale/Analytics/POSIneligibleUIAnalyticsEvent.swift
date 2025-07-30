import WooFoundation

/// POS Ineligible UI specific analytics events
public extension WooAnalyticsEvent {
    enum PointOfSaleIneligibleUI {
        /// Event property key.
        private enum Key {
            static let reason = "reason"
        }

        public static func ineligibleUIShown(reason: POSIneligibleReason) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleIneligibleUIShown, properties: [Key.reason: reason.analyticsValue])
        }

        public static func ineligibleUIRetryTapped(reason: POSIneligibleReason) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .pointOfSaleIneligibleUIRetryTapped, properties: [Key.reason: reason.analyticsValue])
        }
    }
}

private extension POSIneligibleReason {
    var analyticsValue: String {
        switch self {
        case .unsupportedCurrency:
            return "store_currency"
        case .unsupportedWooCommerceVersion:
            return "wc_plugin_version"
        case .featureSwitchDisabled:
            return "feature_switch_disabled"
        case .wooCommercePluginNotFound:
            return "unknown_wc_plugin"
        case .unsupportedIOSVersion:
            return "ios_version"
        case .siteSettingsNotAvailable,
             .selfDeallocated:
            return "other"
        }
    }
}
