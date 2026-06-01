enum POSCapability: String, CaseIterable, Sendable {
    // Raw values match the WordPress capability identifiers reported for a staff member.
    case processSales = "process_sales"
    case viewOrders = "view_orders"
    case applyCoupons = "apply_coupons"
    case createCoupons = "create_coupons"
    case issueRefunds = "issue_refunds"
    case viewPOSSettings = "view_pos_settings"
    case editPOSSettings = "edit_pos_settings"
    case managePOSStaff = "manage_pos_staff"
    case exitPOS = "exit_pos"
}
