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

    private static let userDefaultsKey = "com.woocommerce.pos.pendingCatalogFile"
    private static var userDefaults: UserDefaults = .standard

    /// Configure UserDefaults instance for testing.
    // periphery:ignore - required by tests
    public static func configure(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
    }

    public static func save(_ pending: PendingCatalogFile) {
        if let encoded = try? JSONEncoder().encode(pending) {
            userDefaults.set(encoded, forKey: userDefaultsKey)
        }
    }

    public static func load() -> PendingCatalogFile? {
        guard let data = userDefaults.data(forKey: userDefaultsKey) else {
            return nil
        }
        return try? JSONDecoder().decode(PendingCatalogFile.self, from: data)
    }

    public static func clear() {
        userDefaults.removeObject(forKey: userDefaultsKey)
    }
}
