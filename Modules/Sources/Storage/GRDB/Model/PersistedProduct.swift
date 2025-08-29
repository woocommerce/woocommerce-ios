import Foundation
import GRDB

public struct PersistedProduct: Codable {
    public let id: Int64
    public let siteID: Int64
    public let name: String
    public let productTypeKey: String
    public let fullDescription: String?
    public let shortDescription: String?
    public let sku: String?
    public let globalUniqueID: String?
    public let price: String
    public let downloadable: Bool
    public let parentID: Int64
    public let manageStock: Bool
    public let stockQuantity: Decimal?
    public let stockStatusKey: String

    public init(id: Int64,
                siteID: Int64,
                name: String,
                productTypeKey: String,
                fullDescription: String?,
                shortDescription: String?,
                sku: String?,
                globalUniqueID: String?,
                price: String,
                downloadable: Bool,
                parentID: Int64,
                manageStock: Bool,
                stockQuantity: Decimal?,
                stockStatusKey: String) {
        self.id = id
        self.siteID = siteID
        self.name = name
        self.productTypeKey = productTypeKey
        self.fullDescription = fullDescription
        self.shortDescription = shortDescription
        self.sku = sku
        self.globalUniqueID = globalUniqueID
        self.price = price
        self.downloadable = downloadable
        self.parentID = parentID
        self.manageStock = manageStock
        self.stockQuantity = stockQuantity
        self.stockStatusKey = stockStatusKey
    }
}

extension PersistedProduct: FetchableRecord, PersistableRecord {
    public static var databaseTableName: String { "product" }

    public enum Columns {
        static let id = Column(CodingKeys.id)
        static let siteID = Column(CodingKeys.siteID)
        static let name = Column(CodingKeys.name)
        static let productTypeKey = Column(CodingKeys.productTypeKey)
        static let fullDescription = Column(CodingKeys.fullDescription)
        static let shortDescription = Column(CodingKeys.shortDescription)
        static let sku = Column(CodingKeys.sku)
        static let globalUniqueID = Column(CodingKeys.globalUniqueID)
        static let price = Column(CodingKeys.price)
        static let downloadable = Column(CodingKeys.downloadable)
        static let parentID = Column(CodingKeys.parentID)
        static let manageStock = Column(CodingKeys.manageStock)
        static let stockQuantity = Column(CodingKeys.stockQuantity)
        static let stockStatusKey = Column(CodingKeys.stockStatusKey)
    }
    
    public static let images = hasMany(PersistedProductImage.self)
    public static let attributes = hasMany(PersistedProductAttribute.self)
}

private extension PersistedProduct {
    enum CodingKeys: String, CodingKey {
        case id
        case siteID
        case name
        case productTypeKey
        case fullDescription
        case shortDescription
        case sku
        case globalUniqueID
        case price
        case downloadable
        case parentID
        case manageStock
        case stockQuantity
        case stockStatusKey
    }
}
