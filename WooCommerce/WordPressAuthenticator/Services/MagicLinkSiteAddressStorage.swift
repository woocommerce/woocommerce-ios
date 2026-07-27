import Foundation

/// Persists the login store address in `UserDefaults` so it survives the magic-link
/// cold launch (link opened from Mail) and can be restored on consume. Read-once.
final class MagicLinkSiteAddressStorage {
    static let shared = MagicLinkSiteAddressStorage()

    private let userDefaults: UserDefaults
    private let storageKey = "com.wordpress.authenticator.magicLinkSiteAddress"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    /// nil/empty clears the previous value (latest request wins).
    func save(_ siteAddress: String?) {
        guard let siteAddress, !siteAddress.isEmpty else {
            clear()
            return
        }
        userDefaults.set(siteAddress, forKey: storageKey)
    }

    /// Returns the stored address and clears it; nil if none.
    func consume() -> String? {
        defer { clear() }
        return userDefaults.string(forKey: storageKey)
    }

    private func clear() {
        userDefaults.removeObject(forKey: storageKey)
    }
}
