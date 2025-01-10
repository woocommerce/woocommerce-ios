import Foundation

extension WooAnalyticsEvent {
    enum FilterHistory {
        private enum Keys {
            static let source = "source"
        }

        static func trackEntryPointTapped(from source: FilterSource) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .filterHistoryButtonTapped, properties: [Keys.source: source.rawValue])
        }

        static func trackPastFilterApplied(source: FilterSource) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .filterHistoryPastFilterApplied, properties: [Keys.source: source.rawValue])
        }

        static func trackPastFilterRemoved(source: FilterSource) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .filterHistoryPastFilterRemoved, properties: [Keys.source: source.rawValue])
        }

        static func trackFilterHistoryCleared(source: FilterSource) -> WooAnalyticsEvent {
            WooAnalyticsEvent(statName: .filterHistoryCleared, properties: [Keys.source: source.rawValue])
        }
    }
}
