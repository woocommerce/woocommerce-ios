import Yosemite

extension OrderStatsV4Interval {
    /// Value of the revenue during a stats interval.
    var revenueValue: Decimal {
        return subtotals.grossRevenue
    }
}
