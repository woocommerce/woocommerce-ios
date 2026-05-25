import Foundation

/// The revenue metric displayed on the Performance card. The merchant picks one
/// of these via the segmented control above the card chart.
///
/// Stored per-site as a raw string in `GeneralStoreSettings`.
///
public enum DashboardRevenueStatsType: String, CaseIterable, Sendable {
    /// "Total" revenue — the API's `total_sales` (revenue including taxes and shipping).
    /// Default selection that matches the existing card behavior.
    case total
    /// "Gross" sales — the API's `gross_sales` (revenue before taxes/shipping/refunds/discounts).
    case gross
    /// "Net" revenue — the API's `net_revenue` (revenue after refunds and discounts).
    case net
}
