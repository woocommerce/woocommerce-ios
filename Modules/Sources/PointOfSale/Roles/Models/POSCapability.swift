import Foundation

/// Well-known POS capability identifiers matching backend WooCommerce capabilities.
/// Use at call sites: `permissions.checkPermission(.refundOrders)`.
public enum POSCapability: String, CaseIterable, Sendable {
    // MARK: - Access
    case posAccess = "woocommerce_pos_access"
    case posManageSettings = "woocommerce_pos_manage_settings"

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

    // MARK: - Staff & Overrides
    case approveOverrides = "woocommerce_approve_overrides"

    // MARK: - Customer Data
    case viewCustomerData = "woocommerce_view_customer_data"
    case editCustomerData = "woocommerce_edit_customer_data"

    // MARK: - Audit
    case viewAuditLogs = "woocommerce_view_audit_logs"

    // MARK: - Inventory
    case adjustStock = "woocommerce_adjust_stock"
}
