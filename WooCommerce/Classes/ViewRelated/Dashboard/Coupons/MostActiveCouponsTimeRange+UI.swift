import Foundation
import enum Yosemite.MostActiveCouponsTimeRange
import enum Yosemite.StatsTimeRangeV4

extension MostActiveCouponsTimeRange {
    /// The title of a time range tab.
    var tabTitle: String {
        switch self {
        case .allTime:
            return Localization.allTime
        case .today:
            return StatsTimeRangeV4.today.tabTitle
        case .thisWeek:
            return StatsTimeRangeV4.thisWeek.tabTitle
        case .thisMonth:
            return StatsTimeRangeV4.thisMonth.tabTitle
        case .thisYear:
            return StatsTimeRangeV4.thisYear.tabTitle
        case .custom(let from, let to):
            return StatsTimeRangeV4.custom(from: from, to: to).tabTitle
        }
    }
}

private extension MostActiveCouponsTimeRange {
    enum Localization {
        static let allTime = NSLocalizedString(
            "mostActiveCouponsTimeRange.tabTitle.allTime",
            value: "All time",
            comment: "Tab selector title that shows the all time most active coupons"
        )
    }
}
