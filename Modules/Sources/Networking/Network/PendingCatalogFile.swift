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

    /// When the snapshot's background download started. Passed to the resume parse handler so the
    /// persisted sync watermark reflects the snapshot's real age. A resumed
    /// snapshot must not claim to be current, or the next incremental sync would skip the gap.
    /// See `BackgroundCatalogDownloadCoordinator.resumePendingParseIfNeeded`.
    public let createdAt: Date

    public init(filePath: String, siteID: Int64, createdAt: Date = Date()) {
        self.filePath = filePath
        self.siteID = siteID
        self.createdAt = createdAt
    }

    private enum CodingKeys: String, CodingKey {
        case filePath, siteID, createdAt
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        filePath = try container.decode(String.self, forKey: .filePath)
        siteID = try container.decode(Int64.self, forKey: .siteID)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? .distantPast
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
