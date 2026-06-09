import Foundation

/// The order date type used by WooCommerce Analytics to determine which orders
/// are included in revenue totals.
///
/// Backed by the `woocommerce_date_type` site setting.
///
public enum AnalyticsOrderDateType: String, CaseIterable, Sendable {
    /// Orders that have been paid for. Backend default.
    case paid = "date_paid"
    /// Every order placed, whether paid or not.
    case allOrders = "date_created"
    /// Orders marked as completed.
    case completed = "date_completed"
}
