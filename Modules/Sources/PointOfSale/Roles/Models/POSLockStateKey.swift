import Foundation

/// Per-site UserDefaults key for the POS lock state. Public so the app target can read it
/// at lifecycle boundaries the POS module doesn't see.
public enum POSLockStateKey {
    private static let baseKey = "com.woocommerce.pos.isLocked"

    public static func key(for siteID: Int64) -> String {
        "\(baseKey).\(siteID)"
    }
}
