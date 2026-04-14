import Foundation

/// POS capability identifiers matching backend WooCommerce capabilities.
/// Only capabilities that are actively gated in the iOS app are listed here.
/// Add new cases when the app needs to check a new capability.
public enum POSCapability: String, CaseIterable, Sendable {
    /// View POS settings. Managers and admins have this.
    /// Maps to the backend's `woocommerce_pos_manage_settings` capability.
    case posReadSettings = "woocommerce_pos_manage_settings"
    /// Modify POS settings, manage staff, exit POS. Admins only.
    /// Maps to the backend's `manage_woocommerce` capability (admin/shop_manager only).
    case posWriteSettings = "manage_woocommerce"
    /// Process refunds.
    case refundOrders = "woocommerce_refund_orders"
    /// Void/cancel orders.
    case voidOrders = "woocommerce_void_orders"
    /// Create and apply discount coupons.
    case applyDiscounts = "woocommerce_apply_discounts"

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
        case .posReadSettings, .posWriteSettings:
            return false
        }
    }
}
