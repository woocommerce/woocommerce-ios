import Foundation
import Storage


// MARK: - Storage.SiteVisitStats: ReadOnlyConvertible
//
extension Storage.SiteVisitStats: ReadOnlyConvertible {

    /// Updates the Storage.SiteVisitStats with the ReadOnly.
    ///
    public func update(with stats: Yosemite.SiteVisitStats) {
        siteID = stats.siteID
        date = stats.date
        granularity = stats.granularity.rawValue
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.SiteVisitStats {
        let statItems = items?.map { $0.toReadOnly() } ?? [Yosemite.SiteVisitStatsItem]()

        return SiteVisitStats(siteID: siteID,
                              date: date,
                              granularity: StatGranularity(rawValue: granularity) ?? .day,
                              items: statItems)
    }
}
