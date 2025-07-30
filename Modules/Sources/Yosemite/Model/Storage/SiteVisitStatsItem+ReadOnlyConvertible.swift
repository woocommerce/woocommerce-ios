import Foundation
import Storage


// MARK: - Storage.SiteVisitStatsItem: ReadOnlyConvertible
//
extension Storage.SiteVisitStatsItem: ReadOnlyConvertible {

    /// Updates the Storage.SiteVisitStatsItem with the ReadOnly.
    ///
    public func update(with statsItem: Yosemite.SiteVisitStatsItem) {
        period = statsItem.period
        visitors = Int64(statsItem.visitors)
        views = Int64(statsItem.views)
    }

    /// Returns a ReadOnly version of the receiver.
    ///
    public func toReadOnly() -> Yosemite.SiteVisitStatsItem {
        return SiteVisitStatsItem(period: period ?? "",
                                  visitors: Int(visitors),
                                  views: Int(views))
    }
}
