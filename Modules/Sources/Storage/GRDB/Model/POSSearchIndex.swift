import Foundation
import GRDB

/// Represents a search result from the POS FTS index.
/// Decoded from raw SQL queries against the pos_search_fts virtual table.
public struct POSSearchIndex: Codable, Equatable, FetchableRecord {
    public let siteID: Int64
    public let itemType: ItemType
    public let itemID: Int64
    public let parentProductID: Int64?

    public enum ItemType: String, Codable {
        case product
        case variation
    }

    public init(siteID: Int64,
                itemType: ItemType,
                itemID: Int64,
                parentProductID: Int64?) {
        self.siteID = siteID
        self.itemType = itemType
        self.itemID = itemID
        self.parentProductID = parentProductID
    }
}
