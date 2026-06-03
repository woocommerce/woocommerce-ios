enum POSCapability: String, CaseIterable, Sendable {
    // Raw values match the WordPress capability identifiers reported for a staff member.
    case processSales = "pos_process_sales"
    case viewOrders = "pos_view_orders"
    case applyCoupons = "pos_apply_coupons"
    case createCoupons = "pos_create_coupons"
    case issueRefunds = "pos_issue_refunds"
    case viewPOSSettings = "pos_view_settings"
    case editPOSSettings = "pos_edit_settings"
    case managePOSStaff = "pos_manage_staff"
    case exitPOS = "pos_exit"
}
