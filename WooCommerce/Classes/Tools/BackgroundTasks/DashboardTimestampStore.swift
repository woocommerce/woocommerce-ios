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

    /// Removes a timestamp for the given card and range.
    ///
    static func removeTimestamp(for card: Card, at range: TimeRange, store: UserDefaults = UserDefaults.standard) {
        store.removeObject(forKey: createKey(for: card, at: range))
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
                removeTimestamp(for: card, at: range, store: store)
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

/// Extension to convert `DashboardTimestampStore.Card` into `DashboardCard.CardType`
///
extension DashboardTimestampStore.Card {
    var dashboardCard: DashboardCard.CardType {
        switch self {
        case .performance: return .performance
        case .topPerformers: return .topPerformers
        }
    }
}

extension DashboardTimestampStore {

    /// Returns `true` if it hasn't passed more than 30 minutes since the timestamp was stored.`False` otherwise.
    ///
    static func isTimestampFresh(for card: Card, at range: TimeRange, store: UserDefaults = UserDefaults.standard) -> Bool {

        // Time delta trigger
        let recencyTime: TimeInterval = 30 * 60

        guard let timestamp = loadTimestamp(for: card, at: range, store: store) else {
            return false
        }

        return Date().timeIntervalSince(timestamp) < recencyTime
    }
}
