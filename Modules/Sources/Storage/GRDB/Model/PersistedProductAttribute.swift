import Foundation
import GRDB

// periphery:ignore - TODO: remove ignore when populating database
public struct PersistedProductAttribute: Codable {
    public private(set) var id: Int64?
    public let productID: Int64
    public let name: String
    public let position: Int64
    public let visible: Bool
    public let variation: Bool
    public let options: [String]

    public init(id: Int64? = nil,
                productID: Int64,
                name: String,
                position: Int64,
                visible: Bool,
                variation: Bool,
                options: [String]) {
        self.id = id
        self.productID = productID
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

    public enum Columns {
        static let id = Column(CodingKeys.id)
        static let productID = Column(CodingKeys.productID)
        static let name = Column(CodingKeys.name)
        static let position = Column(CodingKeys.position)
        static let visible = Column(CodingKeys.visible)
        static let variation = Column(CodingKeys.variation)
        static let options = Column(CodingKeys.options)
    }

    public mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}


// periphery:ignore - TODO: remove ignore when populating database
private extension PersistedProductAttribute {
    enum CodingKeys: String, CodingKey {
        case id
        case productID
        case name
        case position
        case visible
        case variation
        case options
    }
}
