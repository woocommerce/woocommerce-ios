enum POSCapability: String, CaseIterable, Sendable {
    // Raw values match the WordPress capability identifiers reported for a staff member.
    case viewPOS = "view_pos"
    case viewPOSSettings = "view_pos_settings"
    case editPOSSettings = "edit_pos_settings"
    case refundShopOrders = "refund_shop_orders"
    case publishShopCoupons = "publish_shop_coupons"
}
