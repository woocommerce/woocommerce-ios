import Foundation
import Storage


// MARK: - Storage.TopEarnerStats: ReadOnlyConvertible
//
extension Storage.TopEarnerStats: ReadOnlyConvertible {

    /// Updates the Storage.Order with the ReadOnly.
    ///
    public func update(with stats: Yosemite.TopEarnerStats) {
        period = stats.period
        granularity = stats.granularity.rawValue
        limit = stats.limit
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.TopEarnerStats {
        let statItems = items?.map { $0.toReadOnly() } ?? [Yosemite.TopEarnerStatsItem]()

        return TopEarnerStats(period: period,
                              granularity: StatGranularity(rawValue: granularity) ?? .day,
                              limit: limit,
                              items: statItems)
    }
}
