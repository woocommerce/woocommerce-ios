import Foundation
import GRDB

// periphery:ignore - TODO: remove ignore when populating database
public struct PersistedProductImage: Codable {
    public let siteID: Int64
    public let id: Int64
    public let productID: Int64
    public let dateCreated: Date
    public let dateModified: Date?
    public let src: String
    public let name: String?
    public let alt: String?

    public init(siteID: Int64,
                id: Int64,
                productID: Int64,
                dateCreated: Date,
                dateModified: Date?,
                src: String,
                name: String?,
                alt: String?) {
        self.siteID = siteID
        self.id = id
        self.productID = productID
        self.dateCreated = dateCreated
        self.dateModified = dateModified
        self.src = src
        self.name = name
        self.alt = alt
    }
}

// periphery:ignore - TODO: remove ignore when populating database
extension PersistedProductImage: FetchableRecord, PersistableRecord {
    public static var databaseTableName: String { "productImage" }

    public static var primaryKey: [String] { [CodingKeys.siteID.stringValue, CodingKeys.id.stringValue] }

    public enum Columns {
        public static let siteID = Column(CodingKeys.siteID)
        public static let id = Column(CodingKeys.id)
        public static let productID = Column(CodingKeys.productID)
        public static let dateCreated = Column(CodingKeys.dateCreated)
        public static let dateModified = Column(CodingKeys.dateModified)
        public static let src = Column(CodingKeys.src)
        public static let name = Column(CodingKeys.name)
        public static let alt = Column(CodingKeys.alt)
    }
}


// periphery:ignore - TODO: remove ignore when populating database
private extension PersistedProductImage {
    enum CodingKeys: String, CodingKey {
        case siteID
        case id
        case productID
        case dateCreated
        case dateModified
        case src
        case name
        case alt
    }
}
