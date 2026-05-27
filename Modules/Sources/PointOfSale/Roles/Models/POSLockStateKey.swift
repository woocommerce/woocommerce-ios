import Foundation

/// UserDefaults key for the per-site POS lock state.
///
/// Public so the app target (`POSTabCoordinator`, `MainTabBarController`) can read and clear
/// the persisted value at app-lifecycle boundaries the POS module doesn't see.
public enum POSLockStateKey {
    private static let baseKey = "com.woocommerce.pos.isLocked"

    public static func key(for siteID: Int64) -> String {
        "\(baseKey).\(siteID)"
    }
}
