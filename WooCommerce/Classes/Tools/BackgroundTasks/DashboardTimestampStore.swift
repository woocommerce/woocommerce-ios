import Foundation
import Yosemite

/// Store to help save and load dashboard cards timestamp information.
/// Uses `UserDefaults` as the default store.
///
struct DashboardTimestampStore {

    /// Supported Cards
    ///
    enum Card: String, CaseIterable {
        case performance
        case topPerformers
    }

    /// Supported time ranges
    ///
    enum TimeRange: String, CaseIterable {
        case `default` // For cards that do not have multiple time ranges
        case today
        case week
        case month
        case year
        case custom
    }

    /// Creates a conjoint key for the timestamp.
    ///
    private static func createKey(for card: Card, at range: TimeRange) -> String {
        "\(card.rawValue)-\(range.rawValue)"
    }

    /// Saves a timestamp for the given card and range.
    ///
    static func saveTimestamp(_ timestamp: Date, for card: Card, at range: TimeRange, store: UserDefaults = UserDefaults.standard) {
        store.set(timestamp, forKey: createKey(for: card, at: range))
    }

    /// Loads the timestamp for the given card and range.
    ///
    static func loadTimestamp(for card: Card, at range: TimeRange, store: UserDefaults = UserDefaults.standard) -> Date? {
        store.object(forKey: createKey(for: card, at: range)) as? Date
    }

    /// Removes all saved timestamps.
    ///
    static func resetStore(store: UserDefaults = UserDefaults.standard) {
        for card in Card.allCases {
            for range in TimeRange.allCases {
                store.removeObject(forKey: createKey(for: card, at: range))
            }
        }
    }
}

/// Extension to convert the `StatsTimeRangeV4` into a `DashboardTimestampStore.TimeRange`
///
extension StatsTimeRangeV4 {
    var timestampRange: DashboardTimestampStore.TimeRange {
        switch self {
        case .today: return .today
        case .thisWeek: return .week
        case .thisMonth: return .month
        case .thisYear: return .year
        case .custom: return .custom
        }
    }
}
