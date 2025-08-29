import Foundation
import GRDB

public struct PersistedProductVariationAttribute: Codable {
    public private(set) var id: Int64?
    public let productVariationID: Int64
    public let name: String
    public let option: String

    public init(id: Int64? = nil,
                productVariationID: Int64,
                name: String,
                option: String) {
        self.id = id
        self.productVariationID = productVariationID
        self.name = name
        self.option = option
    }
}

extension PersistedProductVariationAttribute: FetchableRecord, MutablePersistableRecord {
    public static var databaseTableName: String { "productVariationAttribute" }

    public enum Columns {
        static let id = Column(CodingKeys.id)
        static let productVariationID = Column(CodingKeys.productVariationID)
        static let name = Column(CodingKeys.name)
        static let option = Column(CodingKeys.option)
    }

    public mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }
}


private extension PersistedProductVariationAttribute {
    enum CodingKeys: String, CodingKey {
        case id
        case productVariationID
        case name
        case option
    }
}
