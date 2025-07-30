import Foundation
import Storage


// MARK: - Storage.TopEarnerStats: ReadOnlyConvertible
//
extension Storage.TopEarnerStats: ReadOnlyConvertible {

    /// Updates the Storage.TopEarnerStats with the ReadOnly.
    ///
    public func update(with stats: Yosemite.TopEarnerStats) {
        siteID = stats.siteID
        date = stats.date
        granularity = stats.granularity.rawValue
        limit = stats.limit
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.TopEarnerStats {
        let statItems = items?.map { $0.toReadOnly() } ?? [Yosemite.TopEarnerStatsItem]()

        return TopEarnerStats(siteID: siteID,
                              date: date,
                              granularity: StatGranularity(rawValue: granularity) ?? .day,
                              limit: limit,
                              items: statItems)
    }
}
