import Foundation
import GRDB

// periphery:ignore - TODO: remove ignore when populating database
public struct PersistedSite: Codable {
    // periphery:ignore - TODO: remove ignore when populating database
    public let id: Int64

    // periphery:ignore - TODO: remove ignore when populating database
    public init(id: Int64) {
        self.id = id
    }
}

// periphery:ignore - TODO: remove ignore when populating database
extension PersistedSite: FetchableRecord, PersistableRecord {
    public static var databaseTableName: String { "site" }

    public enum Columns {
        // periphery:ignore - TODO: remove ignore when populating database
        static let id = Column(CodingKeys.id)
    }
}

// periphery:ignore - TODO: remove ignore when populating database
private extension PersistedSite {
    enum CodingKeys: String, CodingKey {
        case id
    }
}
