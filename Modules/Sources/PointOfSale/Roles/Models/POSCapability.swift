enum POSCapability: String, CaseIterable, Sendable {
    // POS-specific capabilities use the `woocommerce_pos_` prefix, matching the keys the staff
    // endpoint reports. Capability matching is by raw value (see `POSStaff.hasCapability`), so
    // non-`woocommerce_pos_` identifiers can be added as cases later without changing the lookup logic.
    case processSales = "woocommerce_pos_process_sales"
    case viewOrders = "woocommerce_pos_view_orders"
    case applyCoupons = "woocommerce_pos_apply_coupons"
    case createCoupons = "woocommerce_pos_create_coupons"
    case issueRefunds = "woocommerce_pos_issue_refunds"
    case viewPOSSettings = "woocommerce_pos_view_settings"
    case editPOSSettings = "woocommerce_pos_edit_settings"
    case managePOSStaff = "woocommerce_pos_manage_staff"
    case exitPOS = "woocommerce_pos_exit"
}
