import Foundation

/// Wipes the persisted POS roles state — the local PINs and the lock-state flags for every site.
/// Public so the app target can call it at a lifecycle boundary the POS module never sees: logout.
///
/// Clears *all* sites, not just the active one: a single login can visit several stores (via
/// site-switching without logging out), so on logout we purge everything rather than guess which
/// stores have PINs. Safe to call when POS roles are disabled or nothing was ever stored.
public enum POSRolesPersistence {
    /// Clears the lock flags even when removing the PINs fails, then rethrows that failure.
    public static func clearAll(userDefaults: UserDefaults = .standard) throws {
        try clearAll(pinStorage: KeychainPOSSecureStorage(), userDefaults: userDefaults)
    }

    static func clearAll(pinStorage: POSSecureStorage, userDefaults: UserDefaults) throws {
        defer { POSLockStateKey.clearAll(in: userDefaults) }
        try POSLocalPINStore.removeAll(storage: pinStorage)
    }
}
