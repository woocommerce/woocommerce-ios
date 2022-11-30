import Foundation
import struct Yosemite.OrderStatsV4
import struct Yosemite.OrderStatsV4Interval

struct StatsIntervalDataParser {

    /// Returns the order stats intervals, ordered by date.
    ///
    static func sortOrderStatsIntervals(from orderStats: OrderStatsV4?) -> [OrderStatsV4Interval] {
        return orderStats?.intervals.sorted(by: { (lhs, rhs) -> Bool in
            let siteTimezone = TimeZone.siteTimezone
            return lhs.dateStart(timeZone: siteTimezone) < rhs.dateStart(timeZone: siteTimezone)
        }) ?? []
    }

    /// Returns the requested stats total data values for every interval in the provided order stats.
    ///
    /// Used to create a line chart with the returned values.
    ///
    static func getChartData(for statsTotal: StatsTotalData, from orderStats: OrderStatsV4?) -> [Double] {
        let intervals = sortOrderStatsIntervals(from: orderStats)
        return intervals.map { interval in
            switch statsTotal {
            case .totalRevenue:
                return (interval.subtotals.grossRevenue as NSNumber).doubleValue
            case .netRevenue:
                return (interval.subtotals.netRevenue as NSNumber).doubleValue
            case .orderCount:
                return Double(interval.subtotals.totalOrders)
            case .averageOrderValue:
                return (interval.subtotals.averageOrderValue as NSNumber).doubleValue
            }
        }
    }

    /// Represents a type of stats total data
    enum StatsTotalData {
        case totalRevenue
        case netRevenue
        case orderCount
        case averageOrderValue
    }
}
