import Foundation

/// Per-site UserDefaults key for the POS lock state. Public so the app target can read it
/// at lifecycle boundaries the POS module doesn't see.
public enum POSLockStateKey {
    private static let baseKey = "com.woocommerce.pos.isLocked"

    public static func key(for siteID: Int64) -> String {
        "\(baseKey).\(siteID)"
    }

    /// Removes the lock-state flag for every site. Used on logout, where we don't know which sites
    /// were visited this session, so we scan for all per-site keys under the shared base.
    static func clearAll(in userDefaults: UserDefaults) {
        let prefix = "\(baseKey)."
        for key in userDefaults.dictionaryRepresentation().keys where key.hasPrefix(prefix) {
            userDefaults.removeObject(forKey: key)
        }
    }
}
