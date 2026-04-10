import Foundation
import GRDB

// periphery:ignore - TODO: remove ignore when populating database
public struct PersistedProductAttribute: Codable {
    public private(set) var id: Int64?
    public let siteID: Int64
    public let productID: Int64
    public let remoteAttributeID: Int64
    public let name: String
    public let position: Int64
    public let visible: Bool
    public let variation: Bool
    public let options: [String]

    public init(id: Int64? = nil,
                siteID: Int64,
                productID: Int64,
                remoteAttributeID: Int64,
                name: String,
                position: Int64,
                visible: Bool,
                variation: Bool,
                options: [String]) {
        self.id = id
        self.siteID = siteID
        self.productID = productID
        self.remoteAttributeID = remoteAttributeID
        self.name = name
        self.position = position
        self.visible = visible
        self.variation = variation
        self.options = options
    }
}

// periphery:ignore - TODO: remove ignore when populating database
extension PersistedProductAttribute: FetchableRecord, MutablePersistableRecord {
    public static var databaseTableName: String { "productAttribute" }

    public static var primaryKey: [String] { [CodingKeys.id.stringValue] }

    public enum Columns {
        public static let id = Column(CodingKeys.id)
        public static let siteID = Column(CodingKeys.siteID)
        public static let productID = Column(CodingKeys.productID)
        public static let remoteAttributeID = Column(CodingKeys.remoteAttributeID)
        public static let name = Column(CodingKeys.name)
        public static let position = Column(CodingKeys.position)
        public static let visible = Column(CodingKeys.visible)
        public static let variation = Column(CodingKeys.variation)
        public static let options = Column(CodingKeys.options)
    }

    public mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }

    public static let product = belongsTo(PersistedProduct.self)
}


// periphery:ignore - TODO: remove ignore when populating database
extension PersistedProductAttribute {
    enum CodingKeys: String, CodingKey {
        case id
        case siteID
        case productID
        case remoteAttributeID
        case name
        case position
        case visible
        case variation
        case options
    }
}
