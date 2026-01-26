import Foundation
import GRDB

public struct POSSearchIndex: Codable, Equatable {
    public let rowid: Int64
    public let siteID: Int64
    public let itemType: ItemType
    public let itemID: Int64
    public let parentProductID: Int64?

    public enum ItemType: String, Codable {
        case simpleProduct
        case variableProduct
        case variation
    }

    public init(rowid: Int64,
                siteID: Int64,
                itemType: ItemType,
                itemID: Int64,
                parentProductID: Int64?) {
        self.rowid = rowid
        self.siteID = siteID
        self.itemType = itemType
        self.itemID = itemID
        self.parentProductID = parentProductID
    }
}

extension POSSearchIndex: FetchableRecord, PersistableRecord {
    public static var databaseTableName: String { "posSearchIndex" }

    public enum Columns {
        public static let rowid = Column(CodingKeys.rowid)
        public static let siteID = Column(CodingKeys.siteID)
        public static let itemType = Column(CodingKeys.itemType)
        public static let itemID = Column(CodingKeys.itemID)
        public static let parentProductID = Column(CodingKeys.parentProductID)
    }
}

private extension POSSearchIndex {
    enum CodingKeys: String, CodingKey {
        case rowid
        case siteID
        case itemType
        case itemID
        case parentProductID
    }
}
