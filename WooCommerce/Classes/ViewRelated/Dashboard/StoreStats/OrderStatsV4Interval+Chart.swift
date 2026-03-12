import Foundation
import Yosemite

extension OrderStatsV4Interval {
    /// Value of the net revenue during a stats interval.
    var revenueValue: Decimal {
        return subtotals.netRevenue
    }
}
