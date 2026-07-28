import Foundation

/// Persists the login store address in `UserDefaults` so it survives the magic-link
/// cold launch (link opened from Mail) and can be restored on consume. Read-once.
final class MagicLinkSiteAddressStorage {
    static let shared = MagicLinkSiteAddressStorage()

    private let userDefaults: UserDefaults
    private let storageKey = "com.wordpress.authenticator.magicLinkSiteAddress"
    private let now: () -> Date

    /// Magic links expire in 60 minutes.
    private let expirationInterval: TimeInterval = 60 * 60

    init(userDefaults: UserDefaults = .standard, now: @escaping () -> Date = { Date() }) {
        self.userDefaults = userDefaults
        self.now = now
    }

    /// nil/empty clears the previous value (latest request wins).
    func save(_ siteAddress: String?) {
        guard let siteAddress, !siteAddress.isEmpty else {
            clear()
            return
        }
        let entry = StoredSiteAddress(siteAddress: siteAddress, timestamp: now())
        userDefaults.set(try? JSONEncoder().encode(entry), forKey: storageKey)
    }

    /// Returns the stored address and clears it; nil if none or expired.
    func consume() -> String? {
        defer { clear() }
        guard let data = userDefaults.data(forKey: storageKey),
              let stored = try? JSONDecoder().decode(StoredSiteAddress.self, from: data),
              now().timeIntervalSince(stored.timestamp) < expirationInterval else {
            return nil
        }
        return stored.siteAddress
    }

    private func clear() {
        userDefaults.removeObject(forKey: storageKey)
    }
}

private extension MagicLinkSiteAddressStorage {
    struct StoredSiteAddress: Codable {
        let siteAddress: String
        let timestamp: Date
    }
}
