import Foundation
import Storage


// MARK: - Storage.SiteSummaryStats: ReadOnlyConvertible
//
extension Storage.SiteSummaryStats: ReadOnlyConvertible {

    /// Updates the Storage.SiteSummaryStats with the ReadOnly.
    ///
    public func update(with stats: Yosemite.SiteSummaryStats) {
        siteID = stats.siteID
        date = stats.date
        period = stats.period.rawValue
        visitors = Int64(stats.visitors)
        views = Int64(stats.views)
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.SiteSummaryStats {
        SiteSummaryStats(siteID: siteID,
                         date: date,
                         period: StatGranularity(rawValue: period) ?? .day,
                         visitors: Int(visitors),
                         views: Int(views))
    }
}
