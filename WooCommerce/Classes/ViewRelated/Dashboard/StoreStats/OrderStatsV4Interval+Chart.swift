import Foundation
import Yosemite

extension OrderStatsV4Interval {
    /// Value of the total sales during a stats interval.
    var revenueValue: Decimal {
        return subtotals.grossRevenue
    }
}
