import Foundation
import GRDB

// periphery:ignore - TODO: remove ignore when populating database
/// Join table linking product variations to images (many-to-many relationship)
public struct PersistedProductVariationImage: Codable {
    public let siteID: Int64
    public let productVariationID: Int64
    public let imageID: Int64

    public init(siteID: Int64,
                productVariationID: Int64,
                imageID: Int64) {
        self.siteID = siteID
        self.productVariationID = productVariationID
        self.imageID = imageID
    }
}

// periphery:ignore - TODO: remove ignore when populating database
extension PersistedProductVariationImage: FetchableRecord, PersistableRecord {
    public static var databaseTableName: String { "productVariationImage" }

    public static var primaryKey: [String] {
        [CodingKeys.siteID.stringValue, CodingKeys.productVariationID.stringValue, CodingKeys.imageID.stringValue]
    }

    public enum Columns {
        public static let siteID = Column(CodingKeys.siteID)
        public static let productVariationID = Column(CodingKeys.productVariationID)
        public static let imageID = Column(CodingKeys.imageID)
    }

    // Association to the actual image
    public static let image = belongsTo(PersistedImage.self,
                                       using: ForeignKey([CodingKeys.siteID.stringValue,
                                                          CodingKeys.imageID.stringValue],
                                                         to: PersistedImage.primaryKey))
}


// periphery:ignore - TODO: remove ignore when populating database
extension PersistedProductVariationImage {
    enum CodingKeys: String, CodingKey {
        case siteID
        case productVariationID
        case imageID
    }
}
