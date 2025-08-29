import Foundation
import GRDB

public struct PersistedSite: Codable {
    public let id: Int64

    public init(id: Int64) {
        self.id = id
    }
}

extension PersistedSite: FetchableRecord, PersistableRecord {
    public static var databaseTableName: String { "site" }

    public enum Columns {
        static let id = Column(CodingKeys.id)
    }
}

private extension PersistedSite {
    enum CodingKeys: String, CodingKey {
        case id
    }
}
