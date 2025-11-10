import Foundation
import GRDB

// periphery:ignore - TODO: remove ignore when populating database
/// Join table linking products to images (many-to-many relationship)
public struct PersistedProductImage: Codable {
    public let siteID: Int64
    public let productID: Int64
    public let imageID: Int64

    public init(siteID: Int64,
                productID: Int64,
                imageID: Int64) {
        self.siteID = siteID
        self.productID = productID
        self.imageID = imageID
    }
}

// periphery:ignore - TODO: remove ignore when populating database
extension PersistedProductImage: FetchableRecord, PersistableRecord {
    public static var databaseTableName: String { "productImage" }

    public static var primaryKey: [String] {
        [CodingKeys.siteID.stringValue, CodingKeys.productID.stringValue, CodingKeys.imageID.stringValue]
    }

    public enum Columns {
        public static let siteID = Column(CodingKeys.siteID)
        public static let productID = Column(CodingKeys.productID)
        public static let imageID = Column(CodingKeys.imageID)
    }

    // Association to the actual image
    public static let image = belongsTo(PersistedImage.self,
                                       using: ForeignKey([CodingKeys.siteID.stringValue,
                                                          CodingKeys.imageID.stringValue],
                                                         to: PersistedImage.primaryKey))
}


// periphery:ignore - TODO: remove ignore when populating database
extension PersistedProductImage {
    enum CodingKeys: String, CodingKey {
        case siteID
        case productID
        case imageID
    }
}
