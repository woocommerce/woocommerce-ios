/// POS permissions from the M1 Guarding table. The raw values are the identifiers M2 plans to use in Core,
/// so synced staff records can map to the same cases.
enum POSCapability: String, CaseIterable, Sendable {
    case processSales = "woocommerce_pos_process_sales"
    case viewOrders = "woocommerce_pos_view_orders"
    case applyCoupons = "woocommerce_pos_apply_coupons"
    case createCoupons = "woocommerce_pos_create_coupons"
    case issueRefunds = "woocommerce_pos_issue_refunds"
    case exitPOS = "woocommerce_pos_exit"
    case manageStoreSettings = "woocommerce_pos_manage_store_settings"
}
