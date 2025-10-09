import Foundation
import GRDB

// periphery:ignore - TODO: remove ignore when populating database
public struct PersistedProductVariationAttribute: Codable {
    public private(set) var id: Int64?
    public let siteID: Int64
    public let productVariationID: Int64
    public let remoteAttributeID: Int64
    public let name: String
    public let option: String

    public init(id: Int64? = nil,
                siteID: Int64,
                productVariationID: Int64,
                remoteAttributeID: Int64,
                name: String,
                option: String) {
        self.id = id
        self.siteID = siteID
        self.productVariationID = productVariationID
        self.remoteAttributeID = remoteAttributeID
        self.name = name
        self.option = option
    }
}

// periphery:ignore - TODO: remove ignore when populating database
// periphery:ignore - TODO: remove ignore when populating database
extension PersistedProductVariationAttribute: FetchableRecord, MutablePersistableRecord {
    public static var databaseTableName: String { "productVariationAttribute" }

    public static var primaryKey: [String] { [CodingKeys.id.stringValue] }

    public enum Columns {
        public static let id = Column(CodingKeys.id)
        public static let siteID = Column(CodingKeys.siteID)
        public static let productVariationID = Column(CodingKeys.productVariationID)
        public static let remoteAttributeID = Column(CodingKeys.remoteAttributeID)
        public static let name = Column(CodingKeys.name)
        public static let option = Column(CodingKeys.option)
    }

    public mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }

    public static let variation = belongsTo(PersistedProductVariation.self)
}


// periphery:ignore - TODO: remove ignore when populating database
extension PersistedProductVariationAttribute {
    enum CodingKeys: String, CodingKey {
        case id
        case siteID
        case productVariationID
        case remoteAttributeID
        case name
        case option
    }
}
