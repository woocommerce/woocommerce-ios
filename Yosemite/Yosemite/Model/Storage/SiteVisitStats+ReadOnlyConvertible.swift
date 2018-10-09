import Foundation
import Storage


// MARK: - Storage.SiteVisitStats: ReadOnlyConvertible
//
extension Storage.SiteVisitStats: ReadOnlyConvertible {

    /// Updates the Storage.Order with the ReadOnly.
    ///
    public func update(with stats: Yosemite.SiteVisitStats) {
        date = stats.date
        granularity = stats.granularity.rawValue
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.SiteVisitStats {
        let statItems = items?.map { $0.toReadOnly() } ?? [Yosemite.SiteVisitStatsItem]()

        return SiteVisitStats(date: date,
                              granularity: StatGranularity(rawValue: granularity) ?? .day,
                              items: statItems)
    }
}
