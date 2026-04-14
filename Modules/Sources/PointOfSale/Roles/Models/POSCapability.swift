import Foundation

/// POS capability identifiers matching backend WooCommerce capabilities.
/// Only capabilities that are actively gated in the iOS app are listed here.
/// Add new cases when the app needs to check a new capability.
public enum POSCapability: String, CaseIterable, Sendable {
    /// View POS settings. Managers and admins.
    case viewPOSSettings = "view_pos_settings"
    /// Modify settings, manage staff, exit POS. Admins only.
    case editPOSSettings = "edit_pos_settings"
    /// Issue refunds.
    case refundShopOrders = "refund_shop_orders"
    /// Create coupons.
    case publishCoupons = "publish_shop_coupons"

    // MARK: - Approval Path

    /// Whether this capability supports backend approval via `/pos/auth/approve` (remote mode).
    ///
    /// - `true`: Remote mode uses the approve endpoint, which returns an audit token.
    /// - `false`: Remote mode uses `/pos/auth/pin/verify` for a capability check only.
    /// - Local mode always uses local PIN verification regardless of this value.
    public var supportsBackendApproval: Bool {
        switch self {
        case .refundShopOrders:
            return true
        case .viewPOSSettings, .editPOSSettings, .publishCoupons:
            return false
        }
    }
}
