import Foundation
import GRDB

public struct PersistedProductVariationImage: Codable {
    public let id: Int64
    public let productVariationID: Int64
    public let dateCreated: Date
    public let dateModified: Date?
    public let src: String
    public let name: String?
    public let alt: String?

    public init(id: Int64,
                productVariationID: Int64,
                dateCreated: Date,
                dateModified: Date?,
                src: String,
                name: String?,
                alt: String?) {
        self.id = id
        self.productVariationID = productVariationID
        self.dateCreated = dateCreated
        self.dateModified = dateModified
        self.src = src
        self.name = name
        self.alt = alt
    }
}

extension PersistedProductVariationImage: FetchableRecord, PersistableRecord {
    public static var databaseTableName: String { "productVariationImage" }

    public enum Columns {
        static let id = Column(CodingKeys.id)
        static let productVariationID = Column(CodingKeys.productVariationID)
        static let dateCreated = Column(CodingKeys.dateCreated)
        static let dateModified = Column(CodingKeys.dateModified)
        static let src = Column(CodingKeys.src)
        static let name = Column(CodingKeys.name)
        static let alt = Column(CodingKeys.alt)
    }
}


private extension PersistedProductVariationImage {
    enum CodingKeys: String, CodingKey {
        case id
        case productVariationID
        case dateCreated
        case dateModified
        case src
        case name
        case alt
    }
}
