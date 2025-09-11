import Foundation
import GRDB

// periphery:ignore - TODO: remove ignore when populating database
public struct PersistedProductVariation: Codable {
    public let id: Int64
    public let siteID: Int64
    public let productID: Int64
    public let sku: String?
    public let globalUniqueID: String?
    public let price: String
    public let downloadable: Bool
    public let fullDescription: String?
    public let manageStock: Bool
    public let stockQuantity: Decimal?
    public let stockStatusKey: String

    public init(id: Int64,
                siteID: Int64,
                productID: Int64,
                sku: String?,
                globalUniqueID: String?,
                price: String,
                downloadable: Bool,
                fullDescription: String?,
                manageStock: Bool,
                stockQuantity: Decimal?,
                stockStatusKey: String) {
        self.id = id
        self.siteID = siteID
        self.productID = productID
        self.sku = sku
        self.globalUniqueID = globalUniqueID
        self.price = price
        self.downloadable = downloadable
        self.fullDescription = fullDescription
        self.manageStock = manageStock
        self.stockQuantity = stockQuantity
        self.stockStatusKey = stockStatusKey
    }
}

// periphery:ignore - TODO: remove ignore when populating database
extension PersistedProductVariation: FetchableRecord, PersistableRecord {
    public static var databaseTableName: String { "productVariation" }

    public static var primaryKey: [String] { [CodingKeys.siteID.stringValue, CodingKeys.id.stringValue] }

    public enum Columns {
        public static let id = Column(CodingKeys.id)
        public static let siteID = Column(CodingKeys.siteID)
        public static let productID = Column(CodingKeys.productID)
        public static let sku = Column(CodingKeys.sku)
        public static let globalUniqueID = Column(CodingKeys.globalUniqueID)
        public static let price = Column(CodingKeys.price)
        public static let downloadable = Column(CodingKeys.downloadable)
        public static let fullDescription = Column(CodingKeys.fullDescription)
        public static let manageStock = Column(CodingKeys.manageStock)
        public static let stockQuantity = Column(CodingKeys.stockQuantity)
        public static let stockStatusKey = Column(CodingKeys.stockStatusKey)
    }

    public static let attributes = hasMany(PersistedProductVariationAttribute.self,
                                           using: ForeignKey([PersistedProductVariationAttribute.CodingKeys.siteID.stringValue,
                                                              PersistedProductVariationAttribute.CodingKeys.productVariationID.stringValue],
                                                             to: primaryKey))
    public static let image = hasOne(PersistedProductVariationImage.self,
                                     using: ForeignKey(PersistedProductVariationImage.primaryKey,
                                                       to: primaryKey))
}


// periphery:ignore - TODO: remove ignore when populating database
private extension PersistedProductVariation {
    enum CodingKeys: String, CodingKey {
        case id
        case siteID
        case productID
        case sku
        case globalUniqueID
        case price
        case downloadable
        case fullDescription
        case manageStock
        case stockQuantity
        case stockStatusKey
    }
}
