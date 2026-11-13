import Foundation
import Yosemite

struct StatsIntervalDataParser {

    /// Returns the stats intervals, ordered by date.
    ///
    static func sortStatsIntervals<Stats: WCAnalyticsStats>(from stats: Stats?) -> [Stats.Interval] {
        let siteTimezone = TimeZone.siteTimezone
        // Skip intervals whose date can't be parsed (bad server data) instead of crashing, then sort by date.
        return (stats?.intervals ?? [])
            .compactMap { interval in interval.dateStart(timeZone: siteTimezone).map { (interval: interval, date: $0) } }
            .sorted { $0.date < $1.date }
            .map { $0.interval }
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
