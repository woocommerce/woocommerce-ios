import Foundation
import GRDB

// periphery:ignore - TODO: remove ignore when populating database
public struct PersistedProductImage: Codable {
    public let id: Int64
    public let productID: Int64
    public let dateCreated: Date
    public let dateModified: Date?
    public let src: String
    public let name: String?
    public let alt: String?

    public init(id: Int64,
                productID: Int64,
                dateCreated: Date,
                dateModified: Date?,
                src: String,
                name: String?,
                alt: String?) {
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

    public enum Columns {
        static let id = Column(CodingKeys.id)
        static let productID = Column(CodingKeys.productID)
        static let dateCreated = Column(CodingKeys.dateCreated)
        static let dateModified = Column(CodingKeys.dateModified)
        static let src = Column(CodingKeys.src)
        static let name = Column(CodingKeys.name)
        static let alt = Column(CodingKeys.alt)
    }
}


// periphery:ignore - TODO: remove ignore when populating database
private extension PersistedProductImage {
    enum CodingKeys: String, CodingKey {
        case id
        case productID
        case dateCreated
        case dateModified
        case src
        case name
        case alt
    }
}
