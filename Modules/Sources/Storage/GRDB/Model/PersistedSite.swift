import Foundation
import GRDB

// periphery:ignore - TODO: remove ignore when populating database
public struct PersistedSite: Codable {
    // periphery:ignore - TODO: remove ignore when populating database
    public let id: Int64
    // periphery:ignore - TODO: remove ignore when populating database
    public var lastCatalogIncrementalSyncDate: Date?
    // periphery:ignore - TODO: remove ignore when populating database
    public var lastCatalogFullSyncDate: Date?

    // periphery:ignore - TODO: remove ignore when populating database
    public init(id: Int64, lastCatalogIncrementalSyncDate: Date? = nil, lastCatalogFullSyncDate: Date? = nil) {
        self.id = id
        self.lastCatalogIncrementalSyncDate = lastCatalogIncrementalSyncDate
        self.lastCatalogFullSyncDate = lastCatalogFullSyncDate
    }
}

// periphery:ignore - TODO: remove ignore when populating database
extension PersistedSite: FetchableRecord, PersistableRecord {
    public static var databaseTableName: String { "site" }

    public enum Columns {
        // periphery:ignore - TODO: remove ignore when populating database
        public static let id = Column(CodingKeys.id)
        // periphery:ignore - TODO: remove ignore when populating database
        public static let lastCatalogIncrementalSyncDate = Column(CodingKeys.lastCatalogIncrementalSyncDate)
        // periphery:ignore - TODO: remove ignore when populating database
        public static let lastCatalogFullSyncDate = Column(CodingKeys.lastCatalogFullSyncDate)
    }
}

// periphery:ignore - TODO: remove ignore when populating database
private extension PersistedSite {
    enum CodingKeys: String, CodingKey {
        case id
        case lastCatalogIncrementalSyncDate
        case lastCatalogFullSyncDate
    }
}
