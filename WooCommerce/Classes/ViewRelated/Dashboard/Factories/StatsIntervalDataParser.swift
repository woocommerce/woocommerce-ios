import Foundation
import Yosemite

struct StatsIntervalDataParser {

    /// Returns the stats intervals, ordered by date.
    ///
    static func sortStatsIntervals<Stats: WCAnalyticsStats>(from stats: Stats?) -> [Stats.Interval] {
        return stats?.intervals.sorted(by: { (lhs, rhs) -> Bool in
            let siteTimezone = TimeZone.siteTimezone
            return lhs.dateStart(timeZone: siteTimezone) < rhs.dateStart(timeZone: siteTimezone)
        }) ?? []
    }

    /// Returns the requested stats total data values for every interval in the provided stats.
    ///
    /// Used to create a line chart with the returned values.
    ///
    static func getChartData<Stats: WCAnalyticsStats>(for statsTotal: Stats.Interval.Totals.TotalData,
                                                      from stats: Stats?) -> [Double] where Stats.Interval.Totals: ParsableStatsTotals {
        let intervals = sortStatsIntervals(from: stats)
        return intervals.map { interval in
            interval.subtotals.getDoubleValue(for: statsTotal)
        }
    }
}
