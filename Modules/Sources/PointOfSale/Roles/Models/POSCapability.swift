import Foundation

/// Well-known POS capability identifiers matching backend WooCommerce capabilities.
/// Use at call sites: `permissions.checkPermission(.refundOrders)`.
public enum POSCapability: String, CaseIterable, Sendable {
    // MARK: - Access
    case posAccess = "woocommerce_pos_access"
    /// View POS settings. Managers and admins have this.
    case posReadSettings = "woocommerce_pos_read_settings"
    /// Modify POS settings, manage staff, exit POS. Admins only.
    case posWriteSettings = "woocommerce_pos_write_settings"

    // MARK: - Order Actions
    case voidOrders = "woocommerce_void_orders"
    case refundOrders = "woocommerce_refund_orders"

    // MARK: - Pricing
    case applyDiscounts = "woocommerce_apply_discounts"
    case overridePrices = "woocommerce_override_prices"

    // MARK: - Reporting
    case viewSalesReports = "woocommerce_view_sales_reports"
    case viewFinancialReports = "woocommerce_view_financial_reports"
    case viewPersonalSales = "woocommerce_view_personal_sales"
    case exportReports = "woocommerce_export_reports"

    // MARK: - Customer Data
    case viewCustomerData = "woocommerce_view_customer_data"
    case editCustomerData = "woocommerce_edit_customer_data"

    // MARK: - Audit
    case viewAuditLogs = "woocommerce_view_audit_logs"

    // MARK: - Inventory
    case adjustStock = "woocommerce_adjust_stock"

    // MARK: - Approval Path

    /// Whether this capability supports backend approval via `/pos/auth/approve` (remote mode).
    ///
    /// - `true`: Remote mode uses the approve endpoint, which returns an audit token.
    /// - `false`: Remote mode uses `/pos/auth/pin/verify` for a capability check only.
    /// - Local mode always uses local PIN verification regardless of this value.
    public var supportsBackendApproval: Bool {
        switch self {
        case .refundOrders, .voidOrders, .applyDiscounts:
            return true
        default:
            return false
        }
    }
}
