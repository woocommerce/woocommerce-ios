import Foundation

extension WooAnalyticsEvent {
    enum FilterHistory {
        private enum Keys {
            static let source = "source"
        }

        enum Source: String {
            case orders
            case products
        }

        static func trackEntryPointTapped(from source: Source) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .filterHistoryButtonTapped, properties: [Keys.source: source.rawValue])
        }

        static func trackPastFilterApplied(source: Source) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .filterHistoryPastFilterApplied, properties: [Keys.source: source.rawValue])
        }

        static func trackPastFilterRemoved(source: Source) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .filterHistoryPastFilterRemoved, properties: [Keys.source: source.rawValue])
        }

        static func trackFilterHistoryCleared(source: Source) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .filterHistoryCleared, properties: [Keys.source: source.rawValue])
        }
    }
}
