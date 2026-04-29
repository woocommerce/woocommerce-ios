import Foundation

/// Persisted pointer to a catalog file that has been downloaded and staged on disk
/// but has not yet been parsed and persisted to the database.
///
/// Used to recover from background-window timeouts: if a background `URLSession` download
/// completes but parse + persist fails to finish in the ~30s execution window iOS grants,
/// the staged file and this record survive across launches and are retried on next foreground.
public struct PendingCatalogFile: Codable {
    public let filePath: String
    public let siteID: Int64

    public init(filePath: String, siteID: Int64) {
        self.filePath = filePath
        self.siteID = siteID
    }
}

/// Persists `PendingCatalogFile` to `UserDefaults`.
///
/// `key` is the seam for site-scoped storage: callers can pass a site-suffixed key
/// (e.g. `"com.woocommerce.pos.pendingCatalogFile.\(siteID)"`)
public struct PendingCatalogFileStore {
    private let userDefaults: UserDefaults
    private let key: String

    public init(userDefaults: UserDefaults = .standard,
                key: String = "com.woocommerce.pos.pendingCatalogFile") {
        self.userDefaults = userDefaults
        self.key = key
    }

    public func save(_ pending: PendingCatalogFile) {
        if let encoded = try? JSONEncoder().encode(pending) {
            userDefaults.set(encoded, forKey: key)
        }
    }

    public func load() -> PendingCatalogFile? {
        guard let data = userDefaults.data(forKey: key) else {
            return nil
        }
        return try? JSONDecoder().decode(PendingCatalogFile.self, from: data)
    }

    public func clear() {
        userDefaults.removeObject(forKey: key)
    }
}
