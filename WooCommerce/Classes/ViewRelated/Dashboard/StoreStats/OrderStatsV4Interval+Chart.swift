import Foundation
import Yosemite

extension OrderStatsV4Interval {
    /// Value of the total sales during a stats interval.
    var revenueValue: Decimal {
        return subtotals.grossRevenue
    }

    /// Returns the revenue value for the given metric, used for the Performance card chart.
    /// "Total" maps to the API's `total_sales` (existing behavior); "Gross" and "Net" use the
    /// dedicated fields.
    func revenueValue(for revenueType: DashboardRevenueStatsType) -> Decimal {
        switch revenueType {
        case .total: return subtotals.grossRevenue
        case .gross: return subtotals.grossSales
        case .net: return subtotals.netRevenue
        }
    }
}
