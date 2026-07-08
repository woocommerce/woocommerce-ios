import Foundation

/// Wipes the persisted POS roles state — the keychain staff caches and the lock-state flags for
/// every site. Public so the app target can call it at a lifecycle boundary the POS module never
/// sees: logout, where no `DefaultPOSAccessSession` instance is alive to clear its own cache.
///
/// Clears *all* sites, not just the active one: a single login can visit several stores (via
/// site-switching without logging out), so on logout we purge everything rather than guess which
/// stores were cached. Safe to call when POS roles are disabled or nothing was ever cached — it
/// degrades to a no-op.
public enum POSRolesPersistence {
    public static func clearAll(userDefaults: UserDefaults = .standard) {
        clearAll(staffStorage: KeychainPOSStaffStorage(), userDefaults: userDefaults)
    }

    static func clearAll(staffStorage: POSStaffKeyValueStorage, userDefaults: UserDefaults) {
        staffStorage.removeAll()
        POSLockStateKey.clearAll(in: userDefaults)
    }
}
